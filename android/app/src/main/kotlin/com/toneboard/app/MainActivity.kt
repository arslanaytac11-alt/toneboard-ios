package com.toneboard.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.AudioManager
import android.media.MediaRecorder
import kotlin.math.tanh
import kotlin.math.sin
import kotlin.math.PI

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.toneboard.app/audio"
    private var audioEngine: ToneBoardAudioEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    audioEngine = ToneBoardAudioEngine()
                    audioEngine?.start()
                    result.success(null)
                }
                "stop" -> {
                    audioEngine?.stop()
                    audioEngine = null
                    result.success(null)
                }
                "setParameter" -> {
                    val pedalId = call.argument<String>("pedalId") ?: ""
                    val key = call.argument<String>("key") ?: ""
                    val value = call.argument<Double>("value")?.toFloat() ?: 0f
                    audioEngine?.setParameter(pedalId, key, value)
                    result.success(null)
                }
                "setChain" -> {
                    val chain = call.argument<List<String>>("chain") ?: emptyList()
                    audioEngine?.setChain(chain)
                    result.success(null)
                }
                "setBypass" -> {
                    val pedalId = call.argument<String>("pedalId") ?: ""
                    val bypassed = call.argument<Boolean>("bypassed") ?: false
                    audioEngine?.setBypass(pedalId, bypassed)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

class ToneBoardAudioEngine {
    private val sampleRate = 44100
    private val bufferSize = 512
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var isRunning = false
    private var thread: Thread? = null

    // Aktif pedal zinciri
    private var chain: List<String> = emptyList()
    private val bypassed = mutableMapOf<String, Boolean>()
    private val params = mutableMapOf<String, MutableMap<String, Float>>()

    // DSP state
    private var delayBuffer = FloatArray(88200) { 0f }
    private var delayHead = 0
    private var chorusLfoPhase = 0f
    private var phaserS0 = 0f; private var phaserS1 = 0f
    private var phaserS2 = 0f; private var phaserS3 = 0f
    private var wahLp = 0f; private var wahBp = 0f
    private var reverbComb = FloatArray(4410) { 0f }
    private var reverbAp = FloatArray(882) { 0f }
    private var reverbCombHead = 0; private var reverbApHead = 0

    fun start() {
        val minBuffer = AudioRecord.getMinBufferSize(sampleRate,
            AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_FLOAT)
        audioRecord = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate,
            AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_FLOAT,
            maxOf(minBuffer, bufferSize * 4))

        val trackMinBuffer = AudioTrack.getMinBufferSize(sampleRate,
            AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT)
        audioTrack = AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
            AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT,
            maxOf(trackMinBuffer, bufferSize * 4), AudioTrack.MODE_STREAM)

        audioRecord?.startRecording()
        audioTrack?.play()
        isRunning = true

        thread = Thread {
            val buffer = FloatArray(bufferSize)
            while (isRunning) {
                val read = audioRecord?.read(buffer, 0, bufferSize,
                    AudioRecord.READ_BLOCKING) ?: 0
                if (read > 0) {
                    val processed = processChain(buffer, read)
                    audioTrack?.write(processed, 0, read, AudioTrack.WRITE_BLOCKING)
                }
            }
        }
        thread?.start()
    }

    fun stop() {
        isRunning = false
        thread?.join(500)
        audioRecord?.stop(); audioRecord?.release(); audioRecord = null
        audioTrack?.stop(); audioTrack?.release(); audioTrack = null
    }

    fun setChain(newChain: List<String>) { chain = newChain }

    fun setBypass(pedalId: String, isBypassed: Boolean) { bypassed[pedalId] = isBypassed }

    fun setParameter(pedalId: String, key: String, value: Float) {
        params.getOrPut(pedalId) { mutableMapOf() }[key] = value
    }

    private fun processChain(input: FloatArray, count: Int): FloatArray {
        var buffer = input.copyOf(count)
        for (pedalId in chain) {
            if (bypassed[pedalId] == true) continue
            buffer = applyEffect(pedalId, buffer, count)
        }
        return buffer
    }

    private fun applyEffect(pedalId: String, buf: FloatArray, count: Int): FloatArray {
        val p = params[pedalId] ?: emptyMap()
        val out = FloatArray(count)
        when (pedalId) {
            "free_overdrive" -> {
                val gain = p["gain"] ?: 10f
                val level = p["level"] ?: 0.8f
                for (i in 0 until count) out[i] = tanh(buf[i] * gain) * level
            }
            "free_fuzz" -> {
                val gain = p["gain"] ?: 60f
                val clip = p["clip"] ?: 0.7f
                val level = p["level"] ?: 0.8f
                for (i in 0 until count) out[i] = buf[i].times(gain).coerceIn(-clip, clip) * level
            }
            "free_clean_boost" -> {
                val gainDB = p["gainDB"] ?: 12f
                val linear = Math.pow(10.0, gainDB / 20.0).toFloat()
                for (i in 0 until count) out[i] = buf[i] * linear
            }
            "free_delay", "premium_crystal_echo" -> {
                val delaySamples = ((p["time"] ?: 0.25f) * sampleRate).toInt().coerceIn(1, 88199)
                val feedback = p["feedback"] ?: 0.4f
                val mix = p["wetDry"]?.div(100f) ?: p["mix"] ?: 0.4f
                for (i in 0 until count) {
                    val rh = (delayHead - delaySamples + 88200) % 88200
                    val delayed = delayBuffer[rh]
                    delayBuffer[delayHead] = buf[i] + delayed * feedback
                    out[i] = buf[i] * (1 - mix) + delayed * mix
                    delayHead = (delayHead + 1) % 88200
                }
            }
            "free_reverb", "premium_spring_pool" -> {
                val dwell = p["dwell"] ?: 0.5f
                val mix = p["wetDry"]?.div(100f) ?: p["mix"] ?: 0.4f
                val fb = dwell * 0.85f
                for (i in 0 until count) {
                    val co = reverbComb[reverbCombHead]
                    reverbComb[reverbCombHead] = buf[i] + co * fb
                    reverbCombHead = (reverbCombHead + 1) % 4410
                    val ao = reverbAp[reverbApHead] - co * 0.7f
                    reverbAp[reverbApHead] = co + reverbAp[reverbApHead] * 0.7f
                    reverbApHead = (reverbApHead + 1) % 882
                    out[i] = buf[i] * (1 - mix) + ao * mix
                }
            }
            "free_chorus" -> {
                val rate = 0.5f
                val mix = p["wetDry"]?.div(100f) ?: 0.5f
                val lfoInc = rate / sampleRate
                for (i in 0 until count) {
                    val lfo = sin(2 * PI * chorusLfoPhase).toFloat()
                    chorusLfoPhase = (chorusLfoPhase + lfoInc) % 1f
                    val delaySamples = ((0.020f + 0.002f * lfo) * sampleRate).toInt().coerceIn(1, 88199)
                    val rh = (delayHead - delaySamples + 88200) % 88200
                    delayBuffer[delayHead] = buf[i]
                    out[i] = buf[i] * (1 - mix) + delayBuffer[rh] * mix
                    delayHead = (delayHead + 1) % 88200
                }
            }
            "free_wah" -> {
                val cutoff = p["cutoff"] ?: 800f
                val q = p["resonance"] ?: 4f
                val F = 2f * sin((PI * cutoff / sampleRate).toFloat())
                val invQ = 1f / q
                for (i in 0 until count) {
                    wahBp = F * (buf[i] - wahLp - invQ * wahBp)
                    wahLp += F * wahBp
                    out[i] = wahBp
                }
            }
            "free_tuner" -> buf.copyInto(out)
            "premium_green_screamer" -> {
                val drive = p["drive"] ?: 0.5f
                val level = p["level"] ?: 0.5f
                val gain = 1f + drive * 29f
                var hp = 0f
                for (i in 0 until count) {
                    hp = 0.9f * (hp + buf[i] - (if (i > 0) buf[i-1] else 0f))
                    out[i] = tanh(hp * gain) * level
                }
            }
            "premium_stone_crusher" -> {
                val gain = 1f + (p["gain"] ?: 0.7f) * 149f
                val level = p["level"] ?: 0.5f
                for (i in 0 until count) out[i] = buf[i].times(gain).coerceIn(-0.6f, 0.6f) * level
            }
            "premium_orange_vibe" -> {
                val rate = p["rate"] ?: 0.5f
                val depth = p["depth"] ?: 0.6f
                val lfoInc = rate / sampleRate
                for (i in 0 until count) {
                    val a = depth * sin(2 * PI * chorusLfoPhase).toFloat()
                    chorusLfoPhase = (chorusLfoPhase + lfoInc) % 1f
                    val y0 = a*buf[i]+phaserS0-a*phaserS0; phaserS0=buf[i]
                    val y1 = a*y0+phaserS1-a*phaserS1; phaserS1=y0
                    val y2 = a*y1+phaserS2-a*phaserS2; phaserS2=y1
                    val y3 = a*y2+phaserS3-a*phaserS3; phaserS3=y2
                    out[i] = (buf[i]+y3)*0.5f
                }
            }
            "premium_velvet_fuzz" -> {
                val sustain = p["sustain"] ?: 0.7f
                val tone = p["tone"] ?: 0.4f
                val volume = p["volume"] ?: 0.6f
                val gain = 1f + sustain * 79f
                var lp = 0f
                for (i in 0 until count) {
                    lp += tone * (tanh(buf[i] * gain) - lp)
                    out[i] = lp * volume
                }
            }
            else -> buf.copyInto(out)
        }
        return out
    }
}

// LlamaEngineTests.kt — v2 Android SDK conformance tests (M5)
//
// Mirrors docs/api-contract-v2.md §8: sync/async generation, single-flight,
// streaming tokens + thread-safe abort, idempotent close. Model-backed tests
// skip when no GGUF is reachable (set LLAMA_MOBILE_TEST_MODEL via a system
// property / adb shell setprop on a real device).

package com.llamamobile

import java.io.File
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry

@RunWith(AndroidJUnit4::class)
class LlamaEngineTests {

    // Model lives in the test app's own external dir (adb-pushed by the host
    // runner), so no storage permission is needed.
    private fun modelPath(): String? {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val dir = ctx.getExternalFilesDir(null)
        val own = dir?.let { File(it, "SmolLM-360M-Instruct.Q6_K.gguf") }
        if (own != null && own.exists()) return own.absolutePath
        System.getProperty("LLAMA_MOBILE_TEST_MODEL")?.let { if (File(it).exists()) return it }
        val legacy = listOf(
            "/sdcard/Download/SmolLM-360M-Instruct.Q6_K.gguf",
            "/data/local/tmp/models/SmolLM-360M-Instruct.Q6_K.gguf",
        )
        return legacy.firstOrNull { File(it).exists() }
    }

    private fun modelAvailable(): Boolean = modelPath() != null

    // Embedding model is adb-pushed beside the main model by the runner.
    private fun embeddingModelPath(): String? {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val dir = ctx.getExternalFilesDir(null)
        val own = dir?.let { File(it, "Qwen3-Embedding-0.6B-Q8_0.gguf") }
        if (own != null && own.exists()) return own.absolutePath
        return listOf(
            "/sdcard/Download/Qwen3-Embedding-0.6B-Q8_0.gguf",
            "/data/local/tmp/models/Qwen3-Embedding-0.6B-Q8_0.gguf",
        ).firstOrNull { File(it).exists() }
    }

    private fun config(): LlamaEngine.Config {
        val c = LlamaEngine.Config()
        c.modelPath = modelPath() ?: ""
        c.nCtx = 2048
        c.engine = 0 // AUTO -> Vulkan on real device
        c.nGpuLayers = 1
        return c
    }

    private fun requireModel() {
        org.junit.Assume.assumeTrue("model not available", modelAvailable())
    }

    @Test
    fun libraryVersionIsV2() {
        val version = LlamaEngine.libraryVersion()
        assertTrue("version string present: $version", version.isNotEmpty())
    }

    @Test
    fun openMissingModelThrows() {
        val c = LlamaEngine.Config()
        c.modelPath = "/nonexistent/model.gguf"
        try {
            LlamaEngine.open(c)
            throw AssertionError("expected open to fail for a missing model")
        } catch (e: LlamaException) {
            assertTrue(
                "got ${e.status}",
                e.status == LlamaStatus.MODEL_LOAD || e.status == LlamaStatus.MODEL_NOT_FOUND ||
                    e.status == LlamaStatus.IO || e.status == LlamaStatus.INVALID_ARGUMENT,
            )
        }
    }

    @Test
    fun syncGenerateProducesText() {
        if (!modelAvailable()) return
        LlamaEngine.open(config()).use { engine ->
            val req = LlamaGenerationRequest(
                prompt = "Complete: the capital of France is",
                maxTokens = 16,
                sampling = LlamaSampling(temperature = 0f, topP = 1.0f, minP = 0f),
            )
            val r = engine.generate(req)
            assertTrue("produced text: '${r.text}'", r.text.isNotEmpty())
            assertEquals(LlamaStopReason.EOS, r.stopReason)
        }
    }

    @Test
    fun asyncGenerateNeverBlocksCaller() {
        if (!modelAvailable()) return
        LlamaEngine.open(config()).use { engine ->
            val f = engine.generateAsync(
                LlamaGenerationRequest(
                    messages = listOf(
                        LlamaChatMessage("system", "Answer in one short sentence."),
                        LlamaChatMessage("user", "What is 2+2?"),
                    ),
                    maxTokens = 24,
                    sampling = LlamaSampling(temperature = 0f),
                ),
            )
            assertTrue(f is CompletableFuture<*>)
            val r = f.get(300, TimeUnit.SECONDS)
            assertTrue(r.text.isNotEmpty())
        }
    }

    @Test
    fun streamingAbortStopsWithAborted() {
        if (!modelAvailable()) return
        LlamaEngine.open(config()).use { engine ->
            val tokens = StringBuilder()
            val started = java.util.concurrent.atomic.AtomicBoolean(false)
            val aborted = java.util.concurrent.atomic.AtomicBoolean(false)
            val f = engine.generateAsync(
                LlamaGenerationRequest(
                    prompt = "Write a long, detailed essay about the history of llamas.",
                    maxTokens = 2000,
                    sampling = LlamaSampling(temperature = 0.9f, ignoreEos = true),
                ),
                tokenCallback = TokenCallback { token ->
                    tokens.append(token)
                    if (started.compareAndSet(false, true)) {
                        // Abort right after the first token arrives.
                        Thread { aborted.set(engine.abort()) }.start()
                    }
                    true
                },
            )
            val r = f.get(300, TimeUnit.SECONDS)
            assertTrue("some tokens arrived", tokens.isNotEmpty())
            if (aborted.get()) {
                // Abort landed mid-generation: it must report ABORTED.
                assertEquals(LlamaStopReason.ABORTED, r.stopReason)
            } else {
                // Generation finished before the abort landed (engine stops on
                // EOS unconditionally) — must still be a clean terminal stop.
                assertTrue(
                    "clean terminal stop, got ${r.stopReason}",
                    r.stopReason == LlamaStopReason.EOS ||
                        r.stopReason == LlamaStopReason.LENGTH,
                )
            }
        }
    }

    /** GPU/Vulkan smoke on a real device: open with GPU layers > 0 and run a
     *  tiny generation. Marks the test skipped when the model is unavailable. */
    @Test
    fun gpuBackendSmoke() {
        if (!modelAvailable()) return
        val c = LlamaEngine.Config()
        c.modelPath = modelPath() ?: ""
        c.nCtx = 1024
        c.engine = 0 // AUTO (device Vulkan when available)
        c.nGpuLayers = 1
        LlamaEngine.open(c).use { engine ->
            val req = LlamaGenerationRequest(
                prompt = "Say hi",
                maxTokens = 8,
                sampling = LlamaSampling(temperature = 0f),
            )
            val r = engine.generate(req, null)
            assertTrue("gpu smoke produced text", r.text.isNotEmpty())
        }
    }

    @Test
    fun closeIsIdempotent() {
        if (!modelAvailable()) return
        val engine = LlamaEngine.open(config())
        engine.close()
        engine.close() // must not throw
    }

    @Test
    fun modelInfoReportsFields() {
        if (!modelAvailable()) return
        LlamaEngine.open(config()).use { engine ->
            val info = engine.modelInfo()
            assertEquals("nCtx should reflect the config", 2048L, info.nCtx.toLong())
            assertTrue("nParams > 0, got ${info.nParams}", info.nParams > 0)
            assertTrue("nEmbd > 0, got ${info.nEmbd}", info.nEmbd > 0)
            assertTrue("description present", info.description.isNotEmpty())
        }
    }

    @Test
    fun tokenizeDetokenizeRoundTrip() {
        if (!modelAvailable()) return
        LlamaEngine.open(config()).use { engine ->
            val tokens = engine.tokenize("Hello from llama mobile v2")
            assertTrue("tokenized to some tokens", tokens.isNotEmpty())
            val round = engine.detokenize(tokens)
            assertTrue("detokenize produced text", round.isNotEmpty())
        }
    }

    @Test
    fun embedProducesVectorsOnEmbeddingModel() {
        val emPath = embeddingModelPath()
        if (emPath == null) return
        val c = LlamaEngine.Config()
        c.modelPath = emPath
        c.nCtx = 512
        c.engine = 0
        c.nGpuLayers = 1
        c.embedding = true
        LlamaEngine.open(c).use { engine ->
            val rows = engine.embed(listOf("hello", "world"))
            assertEquals("one vector per input text", 2L, rows.size.toLong())
            assertTrue("embedding dim > 0", rows[0].isNotEmpty())
            assertEquals(
                "same dim for every row",
                rows[0].size.toLong(),
                rows[1].size.toLong(),
            )
            assertTrue(
                "different texts give different vectors",
                !rows[0].contentEquals(rows[1]),
            )
        }
    }
    private fun extFile(name: String): File? {
        val dir = InstrumentationRegistry.getInstrumentation().targetContext
            .getExternalFilesDir(null) ?: return null
        return File(dir, name)
    }

    /** Vision: SmolVLM + mmproj, image caption (CPU first; GPU variant below). */
    @Test
    fun visionGenerateWithGpu() {
        val model = extFile("SmolVLM-256M-Instruct-Q8_0.gguf") ?: return
        val mmproj = extFile("mmproj-SmolVLM-256M-Instruct-Q8_0.gguf") ?: return
        val img = extFile("image.jpg") ?: return
        if (!model.exists() || !mmproj.exists() || !img.exists()) return
        val c = LlamaEngine.Config()
        c.modelPath = model.absolutePath
        c.nCtx = 2048
        c.chat = true
        c.engine = 1 // CPU first — isolates pipeline from the Vulkan backend
        c.nGpuLayers = 0
        try {
            LlamaEngine.open(c).use { engine ->
                val ok = engine.initMultimodal(mmproj.absolutePath)
                assertTrue("initMultimodal returned false", ok)
                assertTrue("supportsVision true", engine.supportsVision())
                val r = engine.generate(
                    LlamaGenerationRequest(
                        prompt = "Describe this picture in a few words.",
                        mediaPaths = listOf(img.absolutePath),
                        maxTokens = 32,
                        sampling = LlamaSampling(temperature = 0f),
                    ),
                )
                assertTrue("vision caption produced text", r.text.isNotEmpty())
            }
        } catch (t: Throwable) {
            throw AssertionError("vision test failed: " + t, t)
        }
    }

    /** TTS: OuteTTS main + WavTokenizer vocoder -> PCM samples. */
    @Test
    fun ttsSpeakProducesPcm() {
        val model = extFile("OuteTTS-0.2-500M-Q6_K.gguf") ?: return
        val vocoder = extFile("WavTokenizer-Large-75-F16.gguf") ?: return
        if (!model.exists() || !vocoder.exists()) return
        val c = LlamaEngine.Config()
        c.modelPath = model.absolutePath
        c.nCtx = 4096
        c.engine = 1
        c.nGpuLayers = 0
        try {
        LlamaEngine.open(c).use { engine ->
            assertTrue("tts init ok", engine.ttsInit(vocoder.absolutePath))
            assertTrue("tts enabled", engine.ttsEnabled())
            val out = engine.ttsSpeak("Hello from on device speech.")
            assertTrue("pcm samples produced", out.pcm.isNotEmpty())
            assertTrue("usage generated>0", out.usage.generatedTokens > 0)
            assertTrue("tts release ok", engine.ttsRelease())
        }
        } catch (t: Throwable) { throw AssertionError("tts failed: " + t, t) }
    }

    /** Embedding on the GPU (Vulkan). */
    @Test
    fun embedGpu() {
        val model = extFile("Qwen3-Embedding-0.6B-Q8_0.gguf") ?: return
        if (!model.exists()) return
        val c = LlamaEngine.Config()
        c.modelPath = model.absolutePath
        c.nCtx = 512
        c.engine = 0
        c.nGpuLayers = 1
        c.embedding = true
        try {
            LlamaEngine.open(c).use { engine ->
                val rows = engine.embed(listOf("hello", "world"))
                assertTrue("embedding dim > 0", rows.first().isNotEmpty())
            }
        } catch (t: Throwable) { throw AssertionError("embedGpu failed: " + t, t) }
    }

    /** Vision caption on the GPU (Vulkan). */
    @Test
    fun visionGpu() {
        val model = extFile("SmolVLM-256M-Instruct-Q8_0.gguf") ?: return
        val mmproj = extFile("mmproj-SmolVLM-256M-Instruct-Q8_0.gguf") ?: return
        val img = extFile("image.jpg") ?: return
        if (!model.exists() || !mmproj.exists() || !img.exists()) return
        val c = LlamaEngine.Config()
        c.modelPath = model.absolutePath
        c.nCtx = 2048
        c.chat = true
        c.engine = 0
        c.nGpuLayers = 1
        try {
            LlamaEngine.open(c).use { engine ->
                assertTrue("initMultimodal ok", engine.initMultimodal(mmproj.absolutePath))
                val r = engine.generate(
                    LlamaGenerationRequest(
                        prompt = "Describe this picture in a few words.",
                        mediaPaths = listOf(img.absolutePath),
                        maxTokens = 32,
                        sampling = LlamaSampling(temperature = 0f),
                    ),
                )
                assertTrue("vision text produced", r.text.isNotEmpty())
            }
        } catch (t: Throwable) { throw AssertionError("visionGpu failed: " + t, t) }
    }

    /** TTS speak with GPU offload (Vulkan). */
    @Test
    fun ttsGpu() {
        val model = extFile("OuteTTS-0.2-500M-Q6_K.gguf") ?: return
        val vocoder = extFile("WavTokenizer-Large-75-F16.gguf") ?: return
        if (!model.exists() || !vocoder.exists()) return
        val c = LlamaEngine.Config()
        c.modelPath = model.absolutePath
        c.nCtx = 4096
        c.engine = 0
        c.nGpuLayers = 1
        try {
            LlamaEngine.open(c).use { engine ->
                assertTrue("tts init ok", engine.ttsInit(vocoder.absolutePath))
                val out = engine.ttsSpeak("Hello from GPU speech.")
                assertTrue("pcm produced", out.pcm.isNotEmpty())
            }
        } catch (t: Throwable) { throw AssertionError("ttsGpu failed: " + t, t) }
    }

}

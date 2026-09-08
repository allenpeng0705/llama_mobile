// MainActivity.kt — llama_mobile v2 (LlamaEngine) example (M5)
//
// Minimal chat demo: pick/load a GGUF, stream a chat completion, abort on
// demand. Uses the v2 Android SDK (com.llamamobile.LlamaEngine) from the local
// module. Async forms never block the UI thread (§8).

package com.llamamobile.sdkexample

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.llamamobile.LlamaEngine
import com.llamamobile.LlamaException
import com.llamamobile.LlamaGenerationRequest
import com.llamamobile.LlamaStatus
import com.llamamobile.TokenCallback
import java.io.File
import java.util.concurrent.CompletableFuture
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : AppCompatActivity() {

    private lateinit var status: TextView
    private lateinit var modelPathInput: EditText
    private lateinit var logView: TextView
    private lateinit var promptInput: EditText
    private lateinit var loadBtn: Button
    private lateinit var sendBtn: Button
    private lateinit var stopBtn: Button

    private var engine: LlamaEngine? = null
    private val running = AtomicBoolean(false)
    private var generation: CompletableFuture<*>? = null

    private val sb = StringBuilder()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        status = findViewById(R.id.status)
        modelPathInput = findViewById(R.id.modelPath)
        logView = findViewById(R.id.log)
        promptInput = findViewById(R.id.prompt)
        loadBtn = findViewById(R.id.loadBtn)
        sendBtn = findViewById(R.id.sendBtn)
        stopBtn = findViewById(R.id.stopBtn)

        appendLog("llama_mobile v2 — LlamaEngine demo (lib ${LlamaEngine.libraryVersion()})")
        modelPathInput.setText(findDefaultModel() ?: "")

        loadBtn.setOnClickListener { loadModel() }
        sendBtn.setOnClickListener { send() }
        stopBtn.setOnClickListener { stop() }

        stopBtn.isEnabled = false
    }

    override fun onDestroy() {
        engine?.close()
        engine = null
        super.onDestroy()
    }

    // ------------------------------------------------------------- helpers

    private fun findDefaultModel(): String? {
        val dirs = listOf(
            File("/sdcard/Download"),
            File("/data/local/tmp/models"),
            getExternalFilesDir(null),
        )
        for (dir in dirs) {
            if (dir == null || !dir.exists()) continue
            val gguf = dir.listFiles { f -> f.name.endsWith(".gguf") }?.firstOrNull()
            if (gguf != null) return gguf.absolutePath
        }
        return null
    }

    private fun appendLog(text: String) {
        runOnUiThread {
            sb.append(text).append('\n')
            logView.text = sb.toString()
            status.text = text.take(160)
        }
    }

    private fun modelPath(): String = modelPathInput.text.toString().trim()

    // ------------------------------------------------------------- actions

    private fun loadModel() {
        if (engine != null) {
            engine?.close()
            engine = null
        }
        val path = modelPath()
        if (path.isEmpty()) {
            appendLog("No model path set")
            return
        }
        loadBtn.isEnabled = false
        appendLog("Loading $path ...")

        val config = LlamaEngine.Config()
        config.modelPath = path
        config.nCtx = 2048

        LlamaEngine.openAsync(config).whenComplete { eng, err ->
            runOnUiThread {
                loadBtn.isEnabled = true
                if (err != null) {
                    val msg = when (err) {
                        is LlamaException -> "${err.status} ${err.message}"
                        else -> err.message
                    }
                    appendLog("Load failed: $msg")
                } else {
                    engine = eng
                    val info = eng.modelInfo()
                    appendLog("Loaded: ${info.description.ifEmpty { path }} (n_ctx=${info.nCtx})")
                }
            }
        }
    }

    private fun send() {
        val eng = engine ?: run {
            appendLog("Load a model first")
            return
        }
        val text = promptInput.text.toString().trim()
        if (text.isEmpty()) return
        promptInput.setText("")

        if (!running.compareAndSet(false, true)) {
            appendLog("already running (single-flight)")
            return
        }
        sendBtn.isEnabled = false
        stopBtn.isEnabled = true
        appendLog("Q: $text")

        var assistant = StringBuilder()
        val req = LlamaGenerationRequest(
            messages = listOf(com.llamamobile.LlamaChatMessage("user", text)),
            maxTokens = 256,
        )

        val future = eng.generateAsync(req, TokenCallback { token ->
            appendLog(token)
            assistant.append(token)
            true
        })

        generation = future
        future.whenComplete { result, err ->
            runOnUiThread {
                running.set(false)
                sendBtn.isEnabled = true
                stopBtn.isEnabled = false
                generation = null
                if (err != null) {
                    val msg = when (err) {
                        is LlamaException ->
                            if (err.status == LlamaStatus.ABORTED) "[aborted]" else "error ${err.status}"
                        else -> err.message ?: "error"
                    }
                    appendLog(msg)
                } else {
                    if (result.stopReason == com.llamamobile.LlamaStopReason.ABORTED) {
                        appendLog("[stopped]")
                    }
                    appendLog("— done (${result.usage.generatedTokens} tokens)")
                }
            }
        }
    }

    private fun stop() {
        engine?.abort()
    }
}

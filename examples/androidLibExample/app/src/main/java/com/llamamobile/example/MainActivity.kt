package com.llamamobile.example

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.llamamobile.LlamaMobile
import com.llamamobile.LlamaMobile.CacheType
import com.llamamobile.example.databinding.ActivityMainBinding
import kotlin.concurrent.thread

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private var contextHandle: Long = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Set default model path (you'll need to replace this with your actual model path)
        binding.modelPathEditText.setText("/sdcard/Download/llama-model.gguf")

        // Load model button click listener
        binding.loadModelButton.setOnClickListener {
            val modelPath = binding.modelPathEditText.text.toString().trim()
            if (modelPath.isEmpty()) {
                Toast.makeText(this, "Please enter a model path", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            loadModel(modelPath)
        }

        // Generate completion button click listener
        binding.generateButton.setOnClickListener {
            val prompt = binding.promptEditText.text.toString().trim()
            if (prompt.isEmpty()) {
                Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            if (contextHandle == 0L) {
                Toast.makeText(this, "Please load a model first", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            generateCompletion(prompt)
        }
    }

    private fun loadModel(modelPath: String) {
        // Show loading state
        binding.loadModelButton.isEnabled = false
        binding.loadModelButton.text = "Loading..."

        thread {
            try {
                val initParams = LlamaMobile.InitParams(
                    modelPath = modelPath,
                    nCtx = 1024,
                    cacheType = CacheType.MEMORY
                )

                contextHandle = LlamaMobile.initContext(initParams)

                runOnUiThread {
                    if (contextHandle != 0L) {
                        Toast.makeText(this, "Model loaded successfully", Toast.LENGTH_SHORT).show()
                        binding.generateButton.isEnabled = true
                    } else {
                        Toast.makeText(this, "Failed to load model", Toast.LENGTH_SHORT).show()
                    }
                    binding.loadModelButton.isEnabled = true
                    binding.loadModelButton.text = "Load Model"
                }
            } catch (e: Exception) {
                runOnUiThread {
                    Toast.makeText(this, "Error loading model: ${e.message}", Toast.LENGTH_LONG).show()
                    binding.loadModelButton.isEnabled = true
                    binding.loadModelButton.text = "Load Model"
                }
            }
        }
    }

    private fun generateCompletion(prompt: String) {
        // Show loading state
        binding.generateButton.isEnabled = false
        binding.generateButton.text = "Generating..."
        binding.resultTextView.text = "Generating..."

        thread {
            try {
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = prompt,
                    temperature = 0.8f,
                    maxTokens = 100
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)

                runOnUiThread {
                    if (result != null) {
                        binding.resultTextView.text = result
                    } else {
                        binding.resultTextView.text = "Failed to generate completion"
                    }
                    binding.generateButton.isEnabled = true
                    binding.generateButton.text = "Generate"
                }
            } catch (e: Exception) {
                runOnUiThread {
                    binding.resultTextView.text = "Error generating completion: ${e.message}"
                    binding.generateButton.isEnabled = true
                    binding.generateButton.text = "Generate"
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release context when activity is destroyed
        if (contextHandle != 0L) {
            LlamaMobile.releaseContext(contextHandle)
            contextHandle = 0
        }
    }
}

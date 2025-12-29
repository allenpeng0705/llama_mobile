package com.llamamobile.sdkexample

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.llamamobile.sdk.LlamaMobileSdk
import com.llamamobile.sdkexample.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var llamaMobileSdk: LlamaMobileSdk

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Initialize the SDK
        llamaMobileSdk = LlamaMobileSdk()

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

            generateCompletion(prompt)
        }
    }

    private fun loadModel(modelPath: String) {
        // Show loading state
        binding.loadModelButton.isEnabled = false
        binding.loadModelButton.text = "Loading..."

        val config = LlamaMobileSdk.ModelConfig(
            modelPath = modelPath,
            contextSize = 1024,
            useMemoryCache = true
        )

        llamaMobileSdk.loadModel(config, object : LlamaMobileSdk.ResultCallback<Boolean> {
            override fun onSuccess(result: Boolean) {
                runOnUiThread {
                    if (result) {
                        Toast.makeText(this@MainActivity, "Model loaded successfully", Toast.LENGTH_SHORT).show()
                        binding.generateButton.isEnabled = true
                    } else {
                        Toast.makeText(this@MainActivity, "Failed to load model", Toast.LENGTH_SHORT).show()
                    }
                    binding.loadModelButton.isEnabled = true
                    binding.loadModelButton.text = "Load Model"
                }
            }

            override fun onError(error: Throwable) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Error loading model: ${error.message}", Toast.LENGTH_LONG).show()
                    binding.loadModelButton.isEnabled = true
                    binding.loadModelButton.text = "Load Model"
                }
            }
        })
    }

    private fun generateCompletion(prompt: String) {
        // Show loading state
        binding.generateButton.isEnabled = false
        binding.generateButton.text = "Generating..."
        binding.resultTextView.text = "Generating..."

        val config = LlamaMobileSdk.GenerationConfig(
            prompt = prompt,
            temperature = 0.8f,
            maxTokens = 100
        )

        llamaMobileSdk.generate(config, object : LlamaMobileSdk.GenerationListener {
            override fun onGenerationStart(prompt: String) {
                runOnUiThread {
                    binding.statusTextView.text = "Generation started..."
                }
            }

            override fun onGenerationComplete(result: String) {
                runOnUiThread {
                    binding.resultTextView.text = result
                    binding.generateButton.isEnabled = true
                    binding.generateButton.text = "Generate"
                    binding.statusTextView.text = "Generation complete"
                }
            }

            override fun onError(error: Throwable) {
                runOnUiThread {
                    binding.resultTextView.text = "Error generating completion: ${error.message}"
                    binding.generateButton.isEnabled = true
                    binding.generateButton.text = "Generate"
                    binding.statusTextView.text = "Generation failed"
                }
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release SDK resources
        llamaMobileSdk.release()
    }
}
package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.sdk.LlamaMobileSdk
import com.llamamobile.sdkexample.databinding.FragmentEmbeddingsBinding

class EmbeddingsFragment : Fragment() {

    private lateinit var binding: FragmentEmbeddingsBinding
    private lateinit var appState: AppState
    private var isProcessing = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentEmbeddingsBinding.inflate(inflater, container, false)
        appState = (activity as MainActivity).appState
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Set default text
        binding.embedEditText.setText("This is a test sentence")

        // Set up generate embeddings button click listener
        binding.generateEmbeddingsButton.setOnClickListener {
            handleGenerateEmbeddings()
        }

        // Update UI based on model loading status
        updateModelLoadedUI()
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
    }

    private fun handleGenerateEmbeddings() {
        val text = binding.embedEditText.text.toString().trim()
        if (text.isEmpty() || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        if (!appState.enableEmbedding) {
            Toast.makeText(requireContext(), "Embedding is not enabled. Please enable it in Settings and reload the model.", Toast.LENGTH_SHORT).show()
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Generate embeddings
        appState.llamaMobileSdk.generateEmbeddings(text, object : LlamaMobileSdk.ResultCallback<List<Float>> {
            override fun onSuccess(result: List<Float>) {
                isProcessing = false
                updateProcessingUI()
                binding.embeddingsTextView.text = formatEmbeddings(result)
            }

            override fun onError(error: String) {
                isProcessing = false
                updateProcessingUI()
                Toast.makeText(requireContext(), "Embeddings error: $error", Toast.LENGTH_SHORT).show()
            }
        })
    }

    private fun formatEmbeddings(embeddings: List<Float>): String {
        if (embeddings.isEmpty()) {
            return "No embeddings generated"
        }

        val truncated = embeddings.take(20)
        val formatted = truncated.joinToString(", ") { "%.6f".format(it) }
        return if (embeddings.size > 20) {
            "$formatted, ... (and ${embeddings.size - 20} more values)"
        } else {
            formatted
        }
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState.isModelLoaded
        binding.generateEmbeddingsButton.isEnabled = modelLoaded && !isProcessing && appState.enableEmbedding

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else if (!appState.enableEmbedding) {
            binding.statusTextView.text = "Embedding disabled. Enable in Settings and reload model."
            binding.statusTextView.setTextColor(android.graphics.Color.YELLOW)
        } else {
            binding.statusTextView.text = "Model loaded and embedding enabled"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateProcessingUI() {
        binding.generateEmbeddingsButton.isEnabled = appState.isModelLoaded && !isProcessing && appState.enableEmbedding
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}

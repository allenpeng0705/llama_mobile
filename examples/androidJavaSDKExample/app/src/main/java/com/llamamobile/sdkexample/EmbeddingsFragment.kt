package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.util.Log
import android.view.ViewGroup
import android.content.Context
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentEmbeddingsBinding

class EmbeddingsFragment : Fragment() {

    private var _binding: FragmentEmbeddingsBinding? = null
    private val binding get() = _binding!!
    private var appState: AppState? = null
    private var isProcessing = false

    override fun onAttach(context: Context) {
        super.onAttach(context)
        // Access appState when the fragment is properly attached to the activity
        appState = (context as? MainActivity)?.appState
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentEmbeddingsBinding.inflate(inflater, container, false)
        return _binding!!.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            // Set default text
            binding.embedEditText.setText("This is a test sentence")

            // Set up generate embeddings button click listener
            binding.generateEmbeddingsButton.setOnClickListener {
                handleGenerateEmbeddings()
            }

            // Update UI based on model loading status
            updateModelLoadedUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with embeddings fragment initialization
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private fun handleGenerateEmbeddings() {
        val text = binding.embedEditText.text.toString().trim()
        if (text.isEmpty() || isProcessing) {
            return
        }

        val currentAppState = appState ?: run {
            activity?.let { Toast.makeText(it, "App state not initialized", Toast.LENGTH_SHORT).show()}
            return
        }

        if (!currentAppState.isModelLoaded) {
            activity?.let { Toast.makeText(it, "Please load a model first", Toast.LENGTH_SHORT).show()}
            return
        }

        if (!currentAppState.enableEmbedding) {
            activity?.let { Toast.makeText(it, "Embedding is not enabled. Please enable it in Settings and reload the model.", Toast.LENGTH_SHORT).show()}
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Generate embeddings in a background thread
        Thread {
            try {
                // Debug embedding generation
                Log.d("EmbeddingFragment", "- Context handle: ${currentAppState.contextHandle}")
                Log.d("EmbeddingFragment", "- Text: $text")
                
                // Call the new LlamaMobile generateEmbeddings method
                val embeddingsArray = LlamaMobile.generateEmbeddings(currentAppState.contextHandle, text)
                
                Log.d("EmbeddingFragment", "- Embeddings result: ${embeddingsArray?.size ?: "null"}")
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    
                    if (embeddingsArray != null) {
                        val embeddingsList = embeddingsArray.toList()
                        binding.embeddingsTextView.text = formatEmbeddings(embeddingsList)
                        
                        // Show embeddings result section
                        binding.embeddingsSection.visibility = View.VISIBLE
                    } else {
                        activity?.let { Toast.makeText(it, "Embeddings generation failed: null result", Toast.LENGTH_SHORT).show()}
                        
                        // Hide embeddings result section on error
                        binding.embeddingsSection.visibility = View.GONE
                    }
                }
            } catch (e: Exception) {
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "Embeddings error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()}
                    
                    // Hide embeddings result section on error
                    binding.embeddingsSection.visibility = View.GONE
                }
            }
        }.start()
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
        val modelLoaded = appState?.isModelLoaded ?: false
        val embeddingEnabled = appState?.enableEmbedding ?: false
        binding.generateEmbeddingsButton.isEnabled = modelLoaded && !isProcessing && embeddingEnabled

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else if (!embeddingEnabled) {
            binding.statusTextView.text = "Embedding disabled. Enable in Settings and reload model."
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "Model loaded and embedding enabled"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateProcessingUI() {
        binding.generateEmbeddingsButton.isEnabled = (appState?.isModelLoaded ?: false) && !isProcessing && (appState?.enableEmbedding ?: false)
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}

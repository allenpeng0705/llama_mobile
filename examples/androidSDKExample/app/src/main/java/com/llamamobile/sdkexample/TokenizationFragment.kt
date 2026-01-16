package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentTokenizationBinding

class TokenizationFragment : Fragment() {

    private lateinit var binding: FragmentTokenizationBinding
    private lateinit var appState: AppState
    private var isProcessing = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentTokenizationBinding.inflate(inflater, container, false)
        // Access appState safely during fragment creation
        try {
            appState = (activity as MainActivity).appState
        } catch (e: Exception) {
            // Log but don't crash - appState will be set later in onViewCreated if needed
            e.printStackTrace()
        }
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            // Set default text
            binding.tokenizeEditText.setText("Hello world")

            // Set up tokenize button click listener
            binding.tokenizeButton.setOnClickListener {
                handleTokenize()
            }

            // Set up detokenize button click listener
            binding.detokenizeButton.setOnClickListener {
                handleDetokenize()
            }

            // Update UI based on model loading status
            updateModelLoadedUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with tokenization fragment initialization
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
    }

    private fun handleTokenize() {
        val text = binding.tokenizeEditText.text.toString().trim()
        if (text.isEmpty() || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Tokenize the text in a background thread
        Thread {
            try {
                // Call the new LlamaMobile tokenize method
                val tokensArray = LlamaMobile.tokenize(appState.contextHandle, text)
                
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    
                    if (tokensArray != null) {
                        val tokensList = tokensArray.toList()
                        binding.tokensTextView.text = formatTokens(tokensList)
                        binding.detokenizeResultTextView.text = ""
                    } else {
                        Toast.makeText(requireContext(), "Tokenization failed: null result", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    Toast.makeText(requireContext(), "Tokenization error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun handleDetokenize() {
        val tokensText = binding.tokensTextView.text.toString().trim()
        if (tokensText.isEmpty() || tokensText == "No tokens yet" || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Parse the tokens
        val tokens = tokensText.split(" ").mapNotNull { it.toIntOrNull() }
        if (tokens.isEmpty()) {
            Toast.makeText(requireContext(), "No valid tokens to detokenize", Toast.LENGTH_SHORT).show()
            isProcessing = false
            updateProcessingUI()
            return
        }

        // Detokenize the tokens in a background thread
        Thread {
            try {
                // Convert list to array
                val tokensArray = tokens.toIntArray()
                
                // Call the new LlamaMobile detokenize method
                val result = LlamaMobile.detokenize(appState.contextHandle, tokensArray)
                
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    
                    if (result != null) {
                        binding.detokenizeResultTextView.text = result
                    } else {
                        Toast.makeText(requireContext(), "Detokenization failed: null result", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    Toast.makeText(requireContext(), "Detokenization error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun formatTokens(tokens: List<Int>): String {
        return if (tokens.isEmpty()) {
            "No tokens"
        } else {
            tokens.joinToString(" ")
        }
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState.isModelLoaded
        binding.tokenizeButton.isEnabled = modelLoaded && !isProcessing
        binding.detokenizeButton.isEnabled = modelLoaded && !isProcessing

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "Model loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateProcessingUI() {
        binding.tokenizeButton.isEnabled = appState.isModelLoaded && !isProcessing
        binding.detokenizeButton.isEnabled = appState.isModelLoaded && !isProcessing
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}

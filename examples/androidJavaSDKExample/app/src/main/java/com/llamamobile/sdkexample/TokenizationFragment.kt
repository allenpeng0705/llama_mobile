package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.content.Context
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentTokenizationBinding

class TokenizationFragment : Fragment() {

    private var _binding: FragmentTokenizationBinding? = null
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
        _binding = FragmentTokenizationBinding.inflate(inflater, container, false)
        return _binding!!.root
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
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private fun handleTokenize() {
        val text = binding.tokenizeEditText.text.toString().trim()
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

        isProcessing = true
        updateProcessingUI()

        // Tokenize the text in a background thread
        Thread {
            try {
                // Call the new LlamaMobile tokenize method
                val tokensArray = LlamaMobile.tokenize(currentAppState.contextHandle, text)
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    
                    if (tokensArray != null) {
                        val tokensList = tokensArray.toList()
                        binding.tokensTextView.text = formatTokens(tokensList)
                        binding.detokenizeResultTextView.text = ""
                        
                        // Show tokens section
                        binding.tokensSection.visibility = View.VISIBLE
                        binding.detokenizeSection.visibility = View.GONE
                        
                        // Enable detokenize button
                        binding.detokenizeButton.isEnabled = true
                    } else {
                        activity?.let { Toast.makeText(it, "Tokenization failed: null result", Toast.LENGTH_SHORT).show()}
                        
                        // Hide sections on error
                        binding.tokensSection.visibility = View.GONE
                        binding.detokenizeSection.visibility = View.GONE
                        
                        // Disable detokenize button
                        binding.detokenizeButton.isEnabled = false
                    }
                }
            } catch (e: Exception) {
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "Tokenization error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()}
                }
            }
        }.start()
    }

    private fun handleDetokenize() {
        val tokensText = binding.tokensTextView.text.toString().trim()
        if (tokensText.isEmpty() || tokensText == "No tokens yet" || isProcessing) {
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

        isProcessing = true
        updateProcessingUI()

        // Parse the tokens
        val tokens = tokensText.split(" ").mapNotNull { it.toIntOrNull() }
        if (tokens.isEmpty()) {
            activity?.let { Toast.makeText(it, "No valid tokens to detokenize", Toast.LENGTH_SHORT).show()}
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
                val result = LlamaMobile.detokenize(currentAppState.contextHandle, tokensArray)
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    
                    if (result != null) {
                        binding.detokenizeResultTextView.text = result
                        
                        // Show detokenize section
                        binding.detokenizeSection.visibility = View.VISIBLE
                    } else {
                        activity?.let { Toast.makeText(it, "Detokenization failed: null result", Toast.LENGTH_SHORT).show()}
                        
                        // Hide detokenize section on error
                        binding.detokenizeSection.visibility = View.GONE
                    }
                }
            } catch (e: Exception) {
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "Detokenization error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()}
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
        val modelLoaded = appState?.isModelLoaded ?: false
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
        binding.tokenizeButton.isEnabled = (appState?.isModelLoaded ?: false) && !isProcessing
        binding.detokenizeButton.isEnabled = (appState?.isModelLoaded ?: false) && !isProcessing
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}

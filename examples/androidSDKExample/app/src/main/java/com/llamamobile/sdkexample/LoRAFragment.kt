package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.content.Context
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.LlamaMobile.LoraAdapter
import com.llamamobile.sdkexample.databinding.FragmentLoraBinding

class LoRAFragment : Fragment() {

    private var _binding: FragmentLoraBinding? = null
    private val binding get() = _binding!!
    private var appState: AppState? = null
    private var isProcessing = false
    private var isLoraApplied = false

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
        _binding = FragmentLoraBinding.inflate(inflater, container, false)
        return _binding!!.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            // Set default values from AppState
            binding.loraPathEditText.setText(appState?.loraModelPath ?: "")
            binding.loraPathEditText.isEnabled = false // Read-only since we select from settings
            binding.loraScaleEditText.setText("1.0")

            // Set up button click listeners
            binding.applyLoraButton.setOnClickListener {
                handleApplyLora()
            }

            binding.removeLoraButton.setOnClickListener {
                handleRemoveLora()
            }

            // Update UI based on model loading status
            updateModelLoadedUI()
            updateLoraStatusUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with LoRA fragment initialization
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        // Update selected LoRA path when fragment resumes
        binding.loraPathEditText.setText(appState?.loraModelPath ?: "")
        // Check model status when fragment resumes
        updateModelLoadedUI()
        updateLoraStatusUI()
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private fun handleApplyLora() {
        val currentAppState = appState ?: run {
            activity?.let { Toast.makeText(it, "App state not initialized", Toast.LENGTH_SHORT).show()}
            return
        }
        
        val loraPath = currentAppState.loraModelPath.trim()
        val loraScaleText = binding.loraScaleEditText.text.toString().trim()
        
        if (loraPath.isEmpty() || loraScaleText.isEmpty() || isProcessing) {
            activity?.let { 
                Toast.makeText(it, "Please select a LoRA model and enter a valid scale", Toast.LENGTH_SHORT).show()
            }
            return
        }

        if (!currentAppState.isModelLoaded) {
            activity?.let { Toast.makeText(it, "Please load a model first", Toast.LENGTH_SHORT).show()}
            return
        }

        val loraScale = try {
            loraScaleText.toFloat()
        } catch (e: NumberFormatException) {
            activity?.let { Toast.makeText(it, "Please enter a valid scale value", Toast.LENGTH_SHORT).show()}
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Apply LoRA adapter in a background thread
        Thread {
            try {
                // Create LoRA adapter - use positional parameters for Java interop compatibility
                val loraAdapter = LoraAdapter(loraPath, loraScale)
                
                // Log comprehensive information about the LoRA application attempt
                android.util.Log.i("LoRAFragment", "=== LoRA Application Debug Info ===")
                android.util.Log.i("LoRAFragment", "Calling LlamaMobile.applyLoRAAdapters() with:")
                android.util.Log.i("LoRAFragment", "- Context handle: ${currentAppState.contextHandle}")
                android.util.Log.i("LoRAFragment", "- LoRA path: ${loraPath}")
                android.util.Log.i("LoRAFragment", "- LoRA scale: ${loraScale}")
                
                // Check LoRA file validity
                val loraFile = java.io.File(loraPath)
                android.util.Log.i("LoRAFragment", "- LoRA file exists: ${loraFile.exists()}")
                android.util.Log.i("LoRAFragment", "- LoRA file readable: ${loraFile.canRead()}")
                android.util.Log.i("LoRAFragment", "- LoRA file size: ${loraFile.length()} bytes")
                
                // Call the LlamaMobile applyLoRAAdapters method
                val result = LlamaMobile.applyLoraAdapters(currentAppState.contextHandle, arrayOf(loraAdapter))
                
                android.util.Log.i("LoRAFragment", "- applyLoRAAdapters result: ${result}")
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    if (result) {
                        isLoraApplied = true
                        updateLoraStatusUI()
                        activity?.let { Toast.makeText(it, "LoRA adapter applied successfully", Toast.LENGTH_SHORT).show()}
                    } else {
                        activity?.let { Toast.makeText(it, "Failed to apply LoRA adapter. Check logcat for details.", Toast.LENGTH_SHORT).show()}
                    }
                }
            } catch (e: Exception) {
                // Log comprehensive error information
                android.util.Log.e("LoRAFragment", "=== LoRA Application Exception ===")
                android.util.Log.e("LoRAFragment", "Exception type: ${e.javaClass.name}")
                android.util.Log.e("LoRAFragment", "Exception message: ${e.message}")
                
                // Log stack trace
                val stackTrace = e.stackTrace.joinToString("\n") {
                    "  at ${it.className}.${it.methodName}(${it.fileName}:${it.lineNumber})"
                }
                android.util.Log.e("LoRAFragment", "Stack trace:\n$stackTrace")
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "LoRA error: ${e.localizedMessage}. Check logcat for details.", Toast.LENGTH_SHORT).show()}
                }
            } catch (t: Throwable) {
                // Catch all throwables, including native errors
                android.util.Log.e("LoRAFragment", "=== LoRA Application FATAL ERROR ===")
                android.util.Log.e("LoRAFragment", "Throwable type: ${t.javaClass.name}")
                android.util.Log.e("LoRAFragment", "Throwable message: ${t.message}")
                
                // Log stack trace
                val stackTrace = t.stackTrace.joinToString("\n") {
                    "  at ${it.className}.${it.methodName}(${it.fileName}:${it.lineNumber})"
                }
                android.util.Log.e("LoRAFragment", "Stack trace:\n$stackTrace")
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "Fatal LoRA error: ${t.localizedMessage}", Toast.LENGTH_SHORT).show()}
                }
            }
        }.start()
    }

    private fun handleRemoveLora() {
        val currentAppState = appState ?: run {
            activity?.let { Toast.makeText(it, "App state not initialized", Toast.LENGTH_SHORT).show()}
            return
        }
        
        if (!currentAppState.isModelLoaded || isProcessing) {
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Remove LoRA adapter in a background thread
        Thread {
            try {
                // Call the new LlamaMobile removeLoraAdapters method
                LlamaMobile.removeLoraAdapters(currentAppState.contextHandle)
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    isLoraApplied = false
                    updateLoraStatusUI()
                    activity?.let { Toast.makeText(it, "LoRA adapter removed successfully", Toast.LENGTH_SHORT).show()}
                }
            } catch (e: Exception) {
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "LoRA removal error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()}
                }
            }
        }.start()
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState?.isModelLoaded ?: false
        binding.applyLoraButton.isEnabled = modelLoaded && !isProcessing
        binding.removeLoraButton.isEnabled = modelLoaded && !isProcessing && isLoraApplied

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "Model loaded and LoRA ready"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateLoraStatusUI() {
        if (isLoraApplied) {
            binding.loraStatusTextView.text = "✅ LoRA adapter applied"
            binding.loraStatusTextView.setTextColor(android.graphics.Color.GREEN)
        } else {
            binding.loraStatusTextView.text = "❌ No LoRA adapter applied"
            binding.loraStatusTextView.setTextColor(android.graphics.Color.RED)
        }
    }

    private fun updateProcessingUI() {
        binding.applyLoraButton.isEnabled = (appState?.isModelLoaded ?: false) && !isProcessing
        binding.removeLoraButton.isEnabled = (appState?.isModelLoaded ?: false) && !isProcessing && isLoraApplied
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}

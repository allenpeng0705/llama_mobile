package com.llamamobile.sdkexample

import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.LlamaMobile.CompletionParams
import com.llamamobile.sdkexample.databinding.FragmentMultimodalTestBinding
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

private const val TAG = "MultimodalTestFragment"

class MultimodalTestFragment : Fragment() {

    private var _binding: FragmentMultimodalTestBinding? = null
    private val binding get() = _binding!!
    private var appState: AppState? = null
    private var isProcessing = false
    private var selectedImagePath: String? = null
    private val PICK_IMAGE_REQUEST = 1

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
        _binding = FragmentMultimodalTestBinding.inflate(inflater, container, false)
        return _binding!!.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            
            // Set default prompt
            binding.multimodalPromptEditText.setText("Describe the image")

            // Set up select image button click listener
            binding.selectImageButton.setOnClickListener {
                showImageSourceSelectionDialog()
            }

            // Set up back button click listener
            binding.backButton.setOnClickListener {
                // Navigate back to More page
                activity?.onBackPressed()
            }

            // Set up generate response button click listener
            binding.generateResponseButton.setOnClickListener {
                handleGenerateResponse()
            }

            // Add text change listener to prompt edit text
            binding.multimodalPromptEditText.addTextChangedListener(object : android.text.TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
                override fun afterTextChanged(s: android.text.Editable?) {
                    updateGenerateButtonStatus()
                }
            })

            // Update UI based on model loading status
            updateModelLoadedUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with multimodal fragment initialization
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

    private fun showImageSourceSelectionDialog() {
        val options = arrayOf("Select from Gallery", "Use Image from Assets")
        AlertDialog.Builder(requireContext())
            .setTitle("Choose Image Source")
            .setItems(options) { dialog, which ->
                when (which) {
                    0 -> openImagePicker()
                    1 -> showAssetImageSelectionDialog()
                }
            }
            .show()
    }

    private fun showAssetImageSelectionDialog() {
        try {
            // Get all files from assets folder
            val assetManager = requireContext().assets
            val allAssets = assetManager.list("") ?: arrayOf()
            
            // Filter image files
            val imageExtensions = setOf(".png", ".jpg", ".jpeg", ".gif", ".bmp")
            val assetImages = allAssets.filter { asset ->
                imageExtensions.any { asset.lowercase().endsWith(it) }
            }.toTypedArray()
            
            // Show dialog with detected images
            AlertDialog.Builder(requireContext())
                .setTitle("Select Image from Assets")
                .setItems(assetImages) { dialog, which ->
                    val selectedAssetName = assetImages[which]
                    loadImageFromAssets(selectedAssetName)
                }
                .show()
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning assets folder: ${e.message}")
            Toast.makeText(requireContext(), "Failed to scan assets folder", Toast.LENGTH_SHORT).show()
        }
    }

    private fun loadImageFromAssets(assetName: String) {
        try {
            // Open input stream from assets
            val inputStream: InputStream = requireContext().assets.open(assetName)
            
            // Copy the asset to a temporary file in internal storage
            val tempFile = File(requireContext().cacheDir, "asset_$assetName")
            val outputStream = FileOutputStream(tempFile)
            
            // Copy the file
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            
            // Set the selected image path
            selectedImagePath = tempFile.absolutePath
            
            // Load and display the image
            val bitmap = BitmapFactory.decodeFile(selectedImagePath)
            binding.selectedImageView.setImageBitmap(bitmap)
            binding.selectedImageView.visibility = View.VISIBLE
            
            // Update the image status text
            binding.imageStatusTextView.text = "Selected: $assetName"
            binding.imageStatusTextView.visibility = View.VISIBLE
            
            // Update generate button status after image selection
            updateGenerateButtonStatus()
            
            Toast.makeText(requireContext(), "Image loaded from assets: $assetName", Toast.LENGTH_SHORT).show()
        } catch (e: IOException) {
            Log.e(TAG, "Error loading image from assets: $assetName", e)
            Toast.makeText(requireContext(), "Failed to load image from assets", Toast.LENGTH_SHORT).show()
        }
    }

    private fun openImagePicker() {
        // Check if we have the necessary permissions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // For Android 13+, check READ_MEDIA_IMAGES
            if (ContextCompat.checkSelfPermission(requireContext(), android.Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED) {
                // Permission already granted, open image picker
                launchImagePickerIntent()
            } else {
                // Request permission
                requestPermissions(arrayOf(android.Manifest.permission.READ_MEDIA_IMAGES), PICK_IMAGE_REQUEST)
            }
        } else {
            // For Android 12-, check READ_EXTERNAL_STORAGE
            if (ContextCompat.checkSelfPermission(requireContext(), android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                // Permission already granted, open image picker
                launchImagePickerIntent()
            } else {
                // Request permission
                requestPermissions(arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE), PICK_IMAGE_REQUEST)
            }
        }
    }

    private fun launchImagePickerIntent() {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        startActivityForResult(intent, PICK_IMAGE_REQUEST)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PICK_IMAGE_REQUEST) {
            // Check if permission was granted
            if (grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                // Permission granted, open image picker
                launchImagePickerIntent()
            } else {
                // Permission denied
                activity?.let { Toast.makeText(it, "Permission denied to access images", Toast.LENGTH_SHORT).show()}
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == android.app.Activity.RESULT_OK && data != null) {
            val selectedImageUri = data.data
            try {
                selectedImageUri?.let { uri ->
                    // Get bitmap from URI
                    val bitmap = MediaStore.Images.Media.getBitmap(requireActivity().contentResolver, uri)
                    
                    // Save bitmap to a temporary file
                    val tempFile = createTempFileFromBitmap(bitmap)
                    selectedImagePath = tempFile.absolutePath
                    
                    // Update UI to show selected image
                    updateImageSelectionUI(bitmap)
                }
            } catch (e: Exception) {
                Log.e("MultimodalTestFragment", "Error selecting image: ${e.message}")
                activity?.let { Toast.makeText(it, "Error selecting image", Toast.LENGTH_SHORT).show()}
            }
        }
    }

    private fun createTempFileFromBitmap(bitmap: android.graphics.Bitmap): File {
        val tempDir = requireActivity().externalCacheDir
        val tempFile = File.createTempFile("selected_image", ".jpg", tempDir)
        
        try {
            val outputStream = FileOutputStream(tempFile)
            bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, outputStream)
            outputStream.close()
        } catch (e: IOException) {
            e.printStackTrace()
        }
        
        return tempFile
    }

    private fun updateImageSelectionUI(bitmap: android.graphics.Bitmap) {
        binding.selectedImageView.setImageBitmap(bitmap)
        binding.selectedImageView.visibility = View.VISIBLE
        binding.imageStatusTextView.text = "Image selected"
        binding.imageStatusTextView.setTextColor(android.graphics.Color.GREEN)
        
        // Enable generate button if model is loaded
        updateGenerateButtonStatus()
    }

    private fun handleGenerateResponse() {
        val prompt = binding.multimodalPromptEditText.text.toString().trim()
        if (prompt.isEmpty() || isProcessing || selectedImagePath == null) {
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

        if (!LlamaMobile.isMultimodalEnabled(currentAppState.contextHandle)) {
            activity?.let { Toast.makeText(it, "Multimodal not enabled. Please load an mmproj model.", Toast.LENGTH_SHORT).show()}
            return
        }

        // Debug logs
        Log.d(TAG, "handleGenerateResponse called")
        Log.d(TAG, "Prompt: $prompt")
        Log.d(TAG, "Selected image path: $selectedImagePath")
        Log.d(TAG, "Image file exists: ${selectedImagePath?.let { File(it).exists() }}")

        isProcessing = true
        updateProcessingUI()

        // Update debug info on UI thread before starting background task
        activity?.runOnUiThread {
            binding.debugPromptTextView.text = "Prompt: $prompt"
            binding.debugImagePathTextView.text = "Image Path: ${selectedImagePath?.let { ".../${File(it).name}" } ?: "None"}"
        }
        
        // Generate response in a background thread
        Thread {
            try {
                // Use the user's exact prompt without modification
                val fullPrompt = prompt
                
                // Debug log prompt
                Log.d(TAG, "Sending EXACT prompt to model: $fullPrompt")
                
                // Verify image path again before creating params
                val imagePath = selectedImagePath
                if (imagePath == null) {
                    throw Exception("Image path is null")
                }
                
                val imageFile = File(imagePath)
                if (!imageFile.exists()) {
                    throw Exception("Image file does not exist at: $imagePath")
                }
                
                Log.d(TAG, "Image file size: ${imageFile.length()} bytes")
                
                // Create media paths list
                val mediaPaths = listOf(imagePath)
                Log.d(TAG, "Media paths: $mediaPaths")
                
                // Create completion params - try both multimodal and regular to see differences
                val params = try {
                    // First try multimodal params
                    val multimodalParams = CompletionParams.multimodal(
                        prompt = fullPrompt,
                        mediaPaths = mediaPaths,
                        maxTokens = 1024
                    ).copy(
                        grammar = currentAppState.selectedGrammar
                    )
                    Log.d(TAG, "Successfully created multimodal params")
                    multimodalParams
                } catch (e: Exception) {
                    Log.e(TAG, "Error creating multimodal params: ${e.localizedMessage}", e)
                    // Fallback to regular params for debugging
                    CompletionParams(
                        prompt = fullPrompt,
                        maxTokens = 1024,
                        grammar = currentAppState.selectedGrammar
                    )
                }
                
                // Debug log params type
                Log.d(TAG, "Using params type: ${params.javaClass.simpleName}")
                
                // Call the generateCompletion method with params
                Log.d(TAG, "Calling generateCompletion with context handle: ${currentAppState.contextHandle}")
                val result = LlamaMobile.generateCompletion(
                    contextHandle = currentAppState.contextHandle,
                    params = params
                )
                
                val response = result?.text ?: ""
                Log.d(TAG, "Model response length: ${response.length} characters")
                Log.d(TAG, "Model response: $response")
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    binding.responseTextView.text = response
                }
            } catch (e: Exception) {
                // Debug log exception with full stack trace
                Log.e(TAG, "Multimodal error: ${e.localizedMessage}", e)
                
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    val errorMessage = "Multimodal error: ${e.localizedMessage}\nCheck logs for details"
                    binding.responseTextView.text = errorMessage
                    activity?.let { Toast.makeText(it, errorMessage, Toast.LENGTH_LONG).show()}
                }
            }
        }.start()
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState?.isModelLoaded ?: false
        val mmprojModelLoaded = appState?.mmprojModelPath?.isNotEmpty() ?: false
        
        // Update model status
        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "Multimodal ready"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
        
        // Update multimodal model info
        if (appState != null && appState?.mmprojModelPath?.isNotEmpty() == true) {
            val mmprojFileName = File(appState!!.mmprojModelPath).name
            binding.mmprojModelInfoTextView.text = "MMProj model: $mmprojFileName"
            binding.mmprojModelInfoTextView.setTextColor(android.graphics.Color.GREEN)
        } else {
            binding.mmprojModelInfoTextView.text = "No mmproj model loaded"
            binding.mmprojModelInfoTextView.setTextColor(android.graphics.Color.DKGRAY)
        }
        
        // Update multimodal enabled status
        val multimodalEnabled = modelLoaded && LlamaMobile.isMultimodalEnabled(appState?.contextHandle ?: 0)
        binding.multimodalEnabledTextView.text = if (multimodalEnabled) "Yes" else "No"
        binding.multimodalEnabledTextView.setTextColor(if (multimodalEnabled) android.graphics.Color.GREEN else android.graphics.Color.RED)
        
        // Update vision support status
        val visionSupported = modelLoaded && LlamaMobile.supportsVision(appState?.contextHandle ?: 0)
        binding.visionSupportTextView.text = if (visionSupported) "Yes" else "No"
        binding.visionSupportTextView.setTextColor(if (visionSupported) android.graphics.Color.GREEN else android.graphics.Color.RED)
        
        // Update generate button status
        updateGenerateButtonStatus()
    }

    private fun updateGenerateButtonStatus() {
        val modelLoaded = appState?.isModelLoaded ?: false
        val multimodalEnabled = modelLoaded && LlamaMobile.isMultimodalEnabled(appState?.contextHandle ?: 0)
        val imageSelected = selectedImagePath != null
        val promptNotEmpty = binding.multimodalPromptEditText.text.toString().trim().isNotEmpty()
        
        binding.generateResponseButton.isEnabled = modelLoaded && multimodalEnabled && imageSelected && promptNotEmpty && !isProcessing
    }

    private fun updateProcessingUI() {
        binding.generateResponseButton.isEnabled = !isProcessing
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
        binding.responseTextView.text = if (isProcessing) "Generating response..." else binding.responseTextView.text
    }
}
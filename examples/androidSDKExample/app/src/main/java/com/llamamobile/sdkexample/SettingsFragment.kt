package com.llamamobile.sdkexample

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import com.llamamobile.sdkexample.databinding.FragmentSettingsBinding
import android.content.DialogInterface

class SettingsFragment : Fragment() {

    private var _binding: FragmentSettingsBinding? = null
    private val binding get() = _binding!!
    private var appState: AppState? = null
    private lateinit var modelAdapter: ArrayAdapter<String>
    private lateinit var mmprojModelAdapter: ArrayAdapter<String>
    private lateinit var vocoderModelAdapter: ArrayAdapter<String>
    private lateinit var loraModelAdapter: ArrayAdapter<String>

    override fun onAttach(context: Context) {
        super.onAttach(context)
        // Access appState when the fragment is properly attached to the activity
        android.util.Log.d("SettingsFragment", "onAttach() called with context: $context")
        appState = (context as? MainActivity)?.appState
        android.util.Log.d("SettingsFragment", "appState set to: $appState")
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSettingsBinding.inflate(inflater, container, false)
        return _binding!!.root
    }

    override fun onResume() {
        super.onResume()
        // Refresh model list when fragment resumes
        if (activity is MainActivity) {
            val mainActivity = activity as MainActivity
            mainActivity.appState.extractModelsFromAssets(mainActivity)
            setupModelSpinner()
            setupMmprojModelSpinner()
            setupVocoderModelSpinner()
            setupLoRAModelSpinner()
            updateUI()
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            // Initialize model spinners
            setupModelSpinner()
            setupMmprojModelSpinner()
            setupVocoderModelSpinner()
            setupLoRAModelSpinner()

            // Set up parameter controls
            setupParameterControls()

            // Set up model action buttons
            setupModelActionButtons()

            // Set up system prompt
            setupSystemPrompt()

            // Set up feature buttons
            setupFeatureButtons()

            // Update UI based on current state
            updateUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with settings initialization
            e.printStackTrace()
        }
    }

    private fun setupFeatureButtons() {
        // Embedding toggle
        binding.embeddingToggle.setOnCheckedChangeListener {
            _, isChecked ->
            appState?.let {
                it.enableEmbedding = isChecked
            }
        }

        // Custom Template toggle
        binding.customTemplateToggle.setOnCheckedChangeListener {
            _, isChecked ->
            appState?.let {
                it.customTemplate = isChecked
            }
        }

        // Chat Mode toggle
        binding.chatModeToggle.setOnCheckedChangeListener {
            _, isChecked ->
            appState?.let {
                it.chatMode = isChecked
            }
        }

        // Multimodal feature button
        binding.multimodalButton.setOnClickListener {
            try {
                // Access NavController through activity's NavHostFragment
                activity?.let { activity ->
                    val navHostFragment = activity.supportFragmentManager.findFragmentById(R.id.nav_host_fragment_activity_main)
                        as? androidx.navigation.fragment.NavHostFragment
                    navHostFragment?.let {
                        val navController = it.navController
                        navController.navigate(R.id.nav_multimodal)
                    } ?: run {
                        android.util.Log.e("SettingsFragment", "NavHostFragment not found")
                        Toast.makeText(activity, "Navigation error: NavHostFragment not found", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                // Log and show error if navigation fails
                android.util.Log.e("SettingsFragment", "Navigation error: ${e.message}")
                activity?.let { Toast.makeText(it, "Navigation error: ${e.message}", Toast.LENGTH_SHORT).show()}
            }
        }

        // TTS feature button
        binding.ttsButton.setOnClickListener {
            try {
                // Access NavController through activity's NavHostFragment
                activity?.let { activity ->
                    val navHostFragment = activity.supportFragmentManager.findFragmentById(R.id.nav_host_fragment_activity_main)
                        as? androidx.navigation.fragment.NavHostFragment
                    navHostFragment?.let {
                        val navController = it.navController
                        navController.navigate(R.id.nav_tts)
                    } ?: run {
                        android.util.Log.e("SettingsFragment", "NavHostFragment not found")
                        Toast.makeText(activity, "Navigation error: NavHostFragment not found", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                // Log and show error if navigation fails
                android.util.Log.e("SettingsFragment", "Navigation error: ${e.message}")
                activity?.let { Toast.makeText(it, "Navigation error: ${e.message}", Toast.LENGTH_SHORT).show()}
            }
        }
    }

    private fun setupModelSpinner() {
        val appState = this.appState ?: return
        
        val modelNames = if (appState.availableModels.isNotEmpty()) {
            appState.availableModels.map { it.first }
        } else {
            listOf(getString(R.string.no_models_available))
        }

        modelAdapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_item,
            modelNames
        )

        modelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.modelSpinner.adapter = modelAdapter

        // Select the current model if it's available
        val currentModelIndex = appState.availableModels.indexOfFirst { it.second == appState.modelPath }
        if (currentModelIndex >= 0) {
            binding.modelSpinner.setSelection(currentModelIndex)
        }

        // Handle model selection
        binding.modelSpinner.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>, view: View?, position: Int, id: Long) {
                if (appState.availableModels.isNotEmpty()) {
                    appState.modelPath = appState.availableModels[position].second
                }
            }

            override fun onNothingSelected(parent: android.widget.AdapterView<*>) {
                // Do nothing
            }
        }
    }
    
    private fun setupMmprojModelSpinner() {
        val appState = this.appState ?: return
        
        val mmprojModelNames = if (appState.availableMmprojModels.isNotEmpty()) {
            // Add "Empty" option at the beginning
            mutableListOf(getString(R.string.empty_option)) + appState.availableMmprojModels.map { it.first }
        } else {
            listOf(getString(R.string.empty_option))
        }

        mmprojModelAdapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_item,
            mmprojModelNames
        )

        mmprojModelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.mmprojModelSpinner.adapter = mmprojModelAdapter

        // Select "Empty" if no mmproj model is selected, otherwise select the current model
        val currentMmprojModelIndex = if (appState.mmprojModelPath.isEmpty()) {
            0 // Select "Empty" option
        } else {
            // Current model is available, add 1 for the "Empty" option
            1 + appState.availableMmprojModels.indexOfFirst { it.second == appState.mmprojModelPath }
        }
        
        if (currentMmprojModelIndex >= 0) {
            binding.mmprojModelSpinner.setSelection(currentMmprojModelIndex)
        }

        // Handle mmproj model selection
        binding.mmprojModelSpinner.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>, view: View?, position: Int, id: Long) {
                if (position == 0) {
                    // "Empty" option selected
                    appState.mmprojModelPath = ""
                } else if (appState.availableMmprojModels.isNotEmpty()) {
                    // Convert position to available models index (subtract 1 for "Empty" option)
                    appState.mmprojModelPath = appState.availableMmprojModels[position - 1].second
                }
            }

            override fun onNothingSelected(parent: android.widget.AdapterView<*>) {
                // Do nothing
            }
        }
    }
    
    private fun setupVocoderModelSpinner() {
        val appState = this.appState ?: return
        
        val vocoderModelNames = if (appState.availableVocoderModels.isNotEmpty()) {
            // Add "Empty" option at the beginning
            mutableListOf(getString(R.string.empty_option)) + appState.availableVocoderModels.map { it.first }
        } else {
            listOf(getString(R.string.empty_option))
        }

        vocoderModelAdapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_item,
            vocoderModelNames
        )

        vocoderModelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.vocoderModelSpinner.adapter = vocoderModelAdapter

        // Select "Empty" if no vocoder model is selected, otherwise select the current model
        val currentVocoderModelIndex = if (appState.vocoderModelPath.isEmpty()) {
            0 // Select "Empty" option
        } else {
            // Current model is available, add 1 for the "Empty" option
            1 + appState.availableVocoderModels.indexOfFirst { it.second == appState.vocoderModelPath }
        }
        
        if (currentVocoderModelIndex >= 0) {
            binding.vocoderModelSpinner.setSelection(currentVocoderModelIndex)
        }

        // Handle vocoder model selection
        binding.vocoderModelSpinner.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>, view: View?, position: Int, id: Long) {
                if (position == 0) {
                    // "Empty" option selected
                    appState.vocoderModelPath = ""
                } else if (appState.availableVocoderModels.isNotEmpty()) {
                    // Convert position to available models index (subtract 1 for "Empty" option)
                    appState.vocoderModelPath = appState.availableVocoderModels[position - 1].second
                }
            }

            override fun onNothingSelected(parent: android.widget.AdapterView<*>) {
                // Do nothing
            }
        }
    }
    
    private fun setupLoRAModelSpinner() {
        val appState = this.appState ?: return
        
        val loraModelNames = if (appState.availableLoRAModels.isNotEmpty()) {
            // Add "Empty" option at the beginning
            mutableListOf(getString(R.string.empty_option)) + appState.availableLoRAModels.map { it.first }
        } else {
            listOf(getString(R.string.empty_option))
        }

        loraModelAdapter = ArrayAdapter(
            requireContext(),
            android.R.layout.simple_spinner_item,
            loraModelNames
        )

        loraModelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.loraModelSpinner.adapter = loraModelAdapter

        // Select "Empty" if no LoRA model is selected, otherwise select the current model
        val currentLoRAModelIndex = if (appState.loraModelPath.isEmpty()) {
            0 // Select "Empty" option
        } else {
            // Current model is available, add 1 for the "Empty" option
            1 + appState.availableLoRAModels.indexOfFirst { it.second == appState.loraModelPath }
        }
        
        if (currentLoRAModelIndex >= 0) {
            binding.loraModelSpinner.setSelection(currentLoRAModelIndex)
        }

        // Handle LoRA model selection
        binding.loraModelSpinner.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>, view: View?, position: Int, id: Long) {
                if (position == 0) {
                    // "Empty" option selected
                    appState.loraModelPath = ""
                } else if (appState.availableLoRAModels.isNotEmpty()) {
                    // Convert position to available models index (subtract 1 for "Empty" option)
                    appState.loraModelPath = appState.availableLoRAModels[position - 1].second
                }
            }

            override fun onNothingSelected(parent: android.widget.AdapterView<*>) {
                // Do nothing
            }
        }
    }

    private fun setupParameterControls() {
        val appState = this.appState ?: return
        
        // GPU Layers
        binding.gpuLayersValue.text = appState.nGpuLayers.toString()
        binding.decreaseGpuLayers.setOnClickListener {
            if (appState.nGpuLayers > 0) {
                appState.nGpuLayers--
                binding.gpuLayersValue.text = appState.nGpuLayers.toString()
            }
        }
        binding.increaseGpuLayers.setOnClickListener {
            appState.nGpuLayers++
            binding.gpuLayersValue.text = appState.nGpuLayers.toString()
        }

        // Threads
        binding.threadsValue.text = appState.nThreads.toString()
        binding.decreaseThreads.setOnClickListener {
            if (appState.nThreads > 1) {
                appState.nThreads--
                binding.threadsValue.text = appState.nThreads.toString()
            }
        }
        binding.increaseThreads.setOnClickListener {
            appState.nThreads++
            binding.threadsValue.text = appState.nThreads.toString()
        }

        // Context Size
        binding.contextSizeValue.text = appState.nCtx.toString()
        binding.decreaseContextSize.setOnClickListener {
            if (appState.nCtx > 256) {
                appState.nCtx -= 256
                binding.contextSizeValue.text = appState.nCtx.toString()
            }
        }
        binding.increaseContextSize.setOnClickListener {
            if (appState.nCtx < 8192) {
                appState.nCtx += 256
                binding.contextSizeValue.text = appState.nCtx.toString()
            }
        }
    }

    private fun setupModelActionButtons() {
        binding.loadModelButton.setOnClickListener {
            loadModel()
        }

        binding.unloadModelButton.setOnClickListener {
            unloadModel()
        }
    }

    private fun setupSystemPrompt() {
        val appState = this.appState ?: return
        
        binding.systemPromptEditText.setText(appState.systemPrompt)
        binding.systemPromptEditText.setOnFocusChangeListener { _, hasFocus ->
            if (!hasFocus) {
                val newPrompt = binding.systemPromptEditText.text.toString().trim()
                if (newPrompt != appState.systemPrompt) {
                    appState.systemPrompt = newPrompt
                    if (appState.isModelLoaded) {
                        Toast.makeText(
                            context,
                            "System prompt changed. Please reload the model for changes to take effect.",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
            }
        }
    }

    private fun loadModel() {
        val appState = this.appState ?: return
        
        if (appState.availableModels.isEmpty()) {
            activity?.let { Toast.makeText(it, "No models available", Toast.LENGTH_SHORT).show()}
            return
        }

        if (appState.isModelLoaded) {
            activity?.let { Toast.makeText(it, "Model already loaded", Toast.LENGTH_SHORT).show()}
            return
        }

        // Show loading state
        binding.loadModelButton.isEnabled = false
        binding.loadModelButton.text = "Loading..."
        binding.unloadModelButton.isEnabled = false
        hideError()

        appState.loadModel { success ->
            activity?.runOnUiThread {
                binding.loadModelButton.isEnabled = true
                binding.loadModelButton.text = "Load Model"
                binding.unloadModelButton.isEnabled = success

                if (success) {
                    activity?.let { Toast.makeText(it, "Model loaded successfully", Toast.LENGTH_SHORT).show()}
                    updateModelStatusUI()
                } else {
                    showError(appState.errorMessage ?: "Failed to load model")
                }
            }
        }
    }

    private fun unloadModel() {
        val appState = this.appState ?: return
        
        appState.unloadModel()
        activity?.let { Toast.makeText(it, "Model unloaded", Toast.LENGTH_SHORT).show()}
        updateModelStatusUI()
        binding.unloadModelButton.isEnabled = false
        hideError()
    }

    private fun updateUI() {
        updateModelStatusUI()
        val errorMsg = appState?.errorMessage
        if (errorMsg != null) {
            showError(errorMsg)
        }
        
        // Update embedding toggle based on app state
        appState?.let {
            binding.embeddingToggle.isChecked = it.enableEmbedding
            binding.customTemplateToggle.isChecked = it.customTemplate
            binding.chatModeToggle.isChecked = it.chatMode
        }
    }

    private fun updateModelStatusUI() {
        val modelLoaded = appState?.isModelLoaded ?: false
        if (modelLoaded) {
            binding.modelStatusLayout.visibility = View.VISIBLE
            binding.loadModelButton.isEnabled = false
            binding.unloadModelButton.isEnabled = true
        } else {
            binding.modelStatusLayout.visibility = View.GONE
            binding.loadModelButton.isEnabled = true
            binding.unloadModelButton.isEnabled = false
        }
    }

    private fun showError(message: String) {
        binding.errorMessageTextView.text = message
        binding.errorLayout.visibility = View.VISIBLE
    }

    private fun hideError() {
        binding.errorLayout.visibility = View.GONE
    }
}

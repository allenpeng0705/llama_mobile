package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.sdkexample.databinding.FragmentSettingsBinding

class SettingsFragment : Fragment() {

    private lateinit var binding: FragmentSettingsBinding
    private lateinit var appState: AppState
    private lateinit var modelAdapter: ArrayAdapter<String>

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentSettingsBinding.inflate(inflater, container, false)
        appState = (activity as MainActivity).appState
        return binding.root
    }

    override fun onResume() {
        super.onResume()
        // Refresh model list when fragment resumes
        (activity as MainActivity).appState.extractModelsFromAssets(requireContext())
        setupModelSpinner()
        updateUI()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Initialize model spinner
        setupModelSpinner()

        // Set up parameter controls
        setupParameterControls()

        // Set up model action buttons
        setupModelActionButtons()

        // Set up system prompt
        setupSystemPrompt()

        // Update UI based on current state
        updateUI()
    }

    private fun setupModelSpinner() {
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

    private fun setupParameterControls() {
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
        binding.systemPromptEditText.setText(appState.systemPrompt)
        binding.systemPromptEditText.setOnFocusChangeListener { _, hasFocus ->
            if (!hasFocus) {
                val newPrompt = binding.systemPromptEditText.text.toString().trim()
                if (newPrompt != appState.systemPrompt) {
                    appState.systemPrompt = newPrompt
                    if (appState.isModelLoaded) {
                        Toast.makeText(
                            requireContext(),
                            "System prompt changed. Please reload the model for changes to take effect.",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
            }
        }
    }

    private fun loadModel() {
        if (appState.availableModels.isEmpty()) {
            Toast.makeText(requireContext(), "No models available", Toast.LENGTH_SHORT).show()
            return
        }

        if (appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Model already loaded", Toast.LENGTH_SHORT).show()
            return
        }

        // Show loading state
        binding.loadModelButton.isEnabled = false
        binding.loadModelButton.text = "Loading..."
        binding.unloadModelButton.isEnabled = false
        hideError()

        appState.loadModel { success ->
            requireActivity().runOnUiThread {
                binding.loadModelButton.isEnabled = true
                binding.loadModelButton.text = "Load Model"
                binding.unloadModelButton.isEnabled = success

                if (success) {
                    Toast.makeText(requireContext(), "Model loaded successfully", Toast.LENGTH_SHORT).show()
                    updateModelStatusUI()
                } else {
                    showError(appState.errorMessage ?: "Failed to load model")
                }
            }
        }
    }

    private fun unloadModel() {
        appState.unloadModel()
        Toast.makeText(requireContext(), "Model unloaded", Toast.LENGTH_SHORT).show()
        updateModelStatusUI()
        binding.unloadModelButton.isEnabled = false
        hideError()
    }

    private fun updateUI() {
        updateModelStatusUI()
        if (appState.errorMessage != null) {
            showError(appState.errorMessage!!)
        }
    }

    private fun updateModelStatusUI() {
        if (appState.isModelLoaded) {
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

    override fun onResume() {
        super.onResume()
        // Refresh model list in case it changed
        setupModelSpinner()
        updateUI()
    }
}

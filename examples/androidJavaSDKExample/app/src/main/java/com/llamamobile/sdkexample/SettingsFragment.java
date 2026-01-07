package com.llamamobile.sdkexample;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Toast;
import androidx.fragment.app.Fragment;
import com.llamamobile.sdkexample.databinding.FragmentSettingsBinding;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class SettingsFragment extends Fragment {

    private FragmentSettingsBinding binding;
    private AppState appState;
    private ArrayAdapter<String> modelAdapter;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentSettingsBinding.inflate(inflater, container, false);
        appState = ((MainActivity) requireActivity()).getAppState();
        return binding.getRoot();
    }

    @Override
    public void onResume() {
        super.onResume();
        // Refresh model list when fragment resumes
        appState.init(); // Re-extract models
        setupModelSpinner();
        updateUI();
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Initialize model spinner
        setupModelSpinner();

        // Set up parameter controls
        setupParameterControls();

        // Set up model action buttons
        setupModelActionButtons();

        // Set up system prompt
        setupSystemPrompt();

        // Update UI based on current state
        updateUI();
    }

    private void setupModelSpinner() {
        List<String> modelNames = new ArrayList<>();
        List<Map.Entry<String, String>> availableModels = appState.getAvailableModels();
        
        // Extract model names for the spinner
        for (Map.Entry<String, String> entry : availableModels) {
            modelNames.add(entry.getKey());
        }

        if (modelNames.isEmpty()) {
            modelNames.add(getString(R.string.no_models_available));
        }

        modelAdapter = new ArrayAdapter<>(requireContext(), android.R.layout.simple_spinner_item, modelNames);

        modelAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.modelSpinner.setAdapter(modelAdapter);

        // Select the current model if it's available
        String currentModelPath = appState.getModelPath();
        int currentModelIndex = -1;
        for (int i = 0; i < availableModels.size(); i++) {
            if (availableModels.get(i).getValue().equals(currentModelPath)) {
                currentModelIndex = i;
                break;
            }
        }
        if (currentModelIndex >= 0) {
            binding.modelSpinner.setSelection(currentModelIndex);
        }

        // Handle model selection
        binding.modelSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (!availableModels.isEmpty()) {
                    Map.Entry<String, String> selectedModel = availableModels.get(position);
                    appState.setModelPath(selectedModel.getValue());
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // Do nothing
            }
        });
    }

    private void setupParameterControls() {
        // GPU Layers
        binding.gpuLayersValue.setText(String.valueOf(appState.getNGpuLayers()));
        binding.decreaseGpuLayers.setOnClickListener(v -> {
            if (appState.getNGpuLayers() > 0) {
                appState.setNGpuLayers(appState.getNGpuLayers() - 1);
                binding.gpuLayersValue.setText(String.valueOf(appState.getNGpuLayers()));
            }
        });
        binding.increaseGpuLayers.setOnClickListener(v -> {
            appState.setNGpuLayers(appState.getNGpuLayers() + 1);
            binding.gpuLayersValue.setText(String.valueOf(appState.getNGpuLayers()));
        });

        // Threads
        binding.threadsValue.setText(String.valueOf(appState.getNThreads()));
        binding.decreaseThreads.setOnClickListener(v -> {
            if (appState.getNThreads() > 1) {
                appState.setNThreads(appState.getNThreads() - 1);
                binding.threadsValue.setText(String.valueOf(appState.getNThreads()));
            }
        });
        binding.increaseThreads.setOnClickListener(v -> {
            appState.setNThreads(appState.getNThreads() + 1);
            binding.threadsValue.setText(String.valueOf(appState.getNThreads()));
        });

        // Context Size
        binding.contextSizeValue.setText(String.valueOf(appState.getNCtx()));
        binding.decreaseContextSize.setOnClickListener(v -> {
            if (appState.getNCtx() > 256) {
                appState.setNCtx(appState.getNCtx() - 256);
                binding.contextSizeValue.setText(String.valueOf(appState.getNCtx()));
            }
        });
        binding.increaseContextSize.setOnClickListener(v -> {
            if (appState.getNCtx() < 8192) {
                appState.setNCtx(appState.getNCtx() + 256);
                binding.contextSizeValue.setText(String.valueOf(appState.getNCtx()));
            }
        });
    }

    private void setupModelActionButtons() {
        binding.loadModelButton.setOnClickListener(v -> loadModel());
        binding.unloadModelButton.setOnClickListener(v -> unloadModel());
    }

    private void setupSystemPrompt() {
        binding.systemPromptEditText.setText(appState.getSystemPrompt());
        binding.systemPromptEditText.setOnFocusChangeListener((v, hasFocus) -> {
            if (!hasFocus) {
                String newPrompt = binding.systemPromptEditText.getText().toString().trim();
                if (!newPrompt.equals(appState.getSystemPrompt())) {
                    appState.setSystemPrompt(newPrompt);
                    if (appState.isModelLoaded()) {
                        Toast.makeText(
                                requireContext(),
                                "System prompt changed. Please reload the model for changes to take effect.",
                                Toast.LENGTH_SHORT
                        ).show();
                    }
                }
            }
        });
    }

    private void loadModel() {
        if (appState.getAvailableModels().isEmpty()) {
            Toast.makeText(requireContext(), "No models available", Toast.LENGTH_SHORT).show();
            return;
        }

        if (appState.isModelLoaded()) {
            Toast.makeText(requireContext(), "Model already loaded", Toast.LENGTH_SHORT).show();
            return;
        }

        // Show loading state
        binding.loadModelButton.setEnabled(false);
        binding.loadModelButton.setText("Loading...");
        binding.unloadModelButton.setEnabled(false);
        hideError();

        appState.loadModel(success -> {
            requireActivity().runOnUiThread(() -> {
                binding.loadModelButton.setEnabled(true);
                binding.loadModelButton.setText("Load Model");
                binding.unloadModelButton.setEnabled(success);

                if (success) {
                    Toast.makeText(requireContext(), "Model loaded successfully", Toast.LENGTH_SHORT).show();
                    updateModelStatusUI();
                } else {
                    showError(appState.getErrorMessage() != null ? appState.getErrorMessage() : "Failed to load model");
                }
            });
        });
    }

    private void unloadModel() {
        appState.unloadModel();
        Toast.makeText(requireContext(), "Model unloaded", Toast.LENGTH_SHORT).show();
        updateModelStatusUI();
        binding.unloadModelButton.setEnabled(false);
        hideError();
    }

    private void updateUI() {
        updateModelStatusUI();
        if (appState.getErrorMessage() != null) {
            showError(appState.getErrorMessage());
        }
    }

    private void updateModelStatusUI() {
        if (appState.isModelLoaded()) {
            binding.modelStatusLayout.setVisibility(View.VISIBLE);
            binding.loadModelButton.setEnabled(false);
            binding.unloadModelButton.setEnabled(true);
        } else {
            binding.modelStatusLayout.setVisibility(View.GONE);
            binding.loadModelButton.setEnabled(true);
            binding.unloadModelButton.setEnabled(false);
        }
    }

    private void showError(String message) {
        binding.errorMessageTextView.setText(message);
        binding.errorLayout.setVisibility(View.VISIBLE);
    }

    private void hideError() {
        binding.errorLayout.setVisibility(View.GONE);
    }
}
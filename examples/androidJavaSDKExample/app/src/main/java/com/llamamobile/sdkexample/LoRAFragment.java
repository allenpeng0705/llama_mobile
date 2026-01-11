package com.llamamobile.sdkexample;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.EditText;
import android.widget.Button;
import android.widget.Toast;
import android.widget.ProgressBar;

import androidx.fragment.app.Fragment;

import com.llamamobile.sdk.LlamaMobileSdk;

public class LoRAFragment extends Fragment {

    private EditText loraPathEditText;
    private EditText loraScaleEditText;
    private Button applyLoraButton;
    private Button removeLoraButton;
    private TextView loraStatusTextView;
    private ProgressBar progressBar;

    private boolean isProcessing = false;
    private boolean isLoraApplied = false;

    public LoRAFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_lora, container, false);

        loraPathEditText = rootView.findViewById(R.id.loraPathEditText);
        loraScaleEditText = rootView.findViewById(R.id.loraScaleEditText);
        applyLoraButton = rootView.findViewById(R.id.applyLoraButton);
        removeLoraButton = rootView.findViewById(R.id.removeLoraButton);
        loraStatusTextView = rootView.findViewById(R.id.loraStatusTextView);
        progressBar = rootView.findViewById(R.id.progressBar);

        applyLoraButton.setOnClickListener(v -> handleApplyLora());
        removeLoraButton.setOnClickListener(v -> handleRemoveLora());

        updateProcessingUI();
        updateLoraStatusUI();

        return rootView;
    }

    private void handleApplyLora() {
        String loraPath = loraPathEditText.getText().toString().trim();
        String scaleText = loraScaleEditText.getText().toString().trim();
        if (loraPath.isEmpty() || scaleText.isEmpty() || isProcessing) {
            return;
        }

        float loraScale;
        try {
            loraScale = Float.parseFloat(scaleText);
        } catch (NumberFormatException e) {
            Toast.makeText(getContext(), "Invalid scale value", Toast.LENGTH_SHORT).show();
            return;
        }

        isProcessing = true;
        updateProcessingUI();

        MainActivity mainActivity = (MainActivity) getActivity();
        if (mainActivity != null) {
            AppState appState = mainActivity.getAppState();
            LlamaMobileSdk llamaMobileSdk = appState.getLlamaMobileSdk();
            llamaMobileSdk.applyLoRA(loraPath, loraScale, new LlamaMobileSdk.ResultCallback<Boolean>() {
                @Override
                public void onSuccess(Boolean result) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        isLoraApplied = result;
                        updateProcessingUI();
                        updateLoraStatusUI();
                    });
                }

                @Override
                public void onError(Exception e) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        Toast.makeText(getContext(), "Failed to apply LoRA: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        updateProcessingUI();
                    });
                }
            });
        }
    }

    private void handleRemoveLora() {
        if (isProcessing || !isLoraApplied) {
            return;
        }

        isProcessing = true;
        updateProcessingUI();

        MainActivity mainActivity = (MainActivity) getActivity();
        if (mainActivity != null) {
            AppState appState = mainActivity.getAppState();
            LlamaMobileSdk llamaMobileSdk = appState.getLlamaMobileSdk();
            llamaMobileSdk.removeLoraAdapters(new LlamaMobileSdk.ResultCallback<Boolean>() {
                @Override
                public void onSuccess(Boolean result) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        isLoraApplied = false;
                        updateProcessingUI();
                        updateLoraStatusUI();
                    });
                }

                @Override
                public void onError(Exception e) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        Toast.makeText(getContext(), "Failed to remove LoRA: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        updateProcessingUI();
                    });
                }
            });
        }
    }

    private void updateLoraStatusUI() {
        if (loraStatusTextView != null) {
            if (isLoraApplied) {
                loraStatusTextView.setText("✅ LoRA adapter applied");
                loraStatusTextView.setTextColor(getResources().getColor(android.R.color.holo_green_dark));
            } else {
                loraStatusTextView.setText("❌ No LoRA adapter applied");
                loraStatusTextView.setTextColor(getResources().getColor(android.R.color.holo_red_dark));
            }
        }
    }

    private void updateProcessingUI() {
        if (getView() == null) return;

        progressBar.setVisibility(isProcessing ? View.VISIBLE : View.GONE);
        applyLoraButton.setEnabled(!isProcessing);
        removeLoraButton.setEnabled(!isProcessing && isLoraApplied);
    }
}
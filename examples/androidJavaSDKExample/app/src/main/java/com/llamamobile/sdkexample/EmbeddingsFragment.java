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

import java.util.List;

public class EmbeddingsFragment extends Fragment {

    private EditText embedEditText;
    private Button generateEmbeddingsButton;
    private TextView embeddingsTextView;
    private ProgressBar progressBar;

    private boolean isProcessing = false;

    public EmbeddingsFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_embeddings, container, false);

        embedEditText = rootView.findViewById(R.id.embedEditText);
        generateEmbeddingsButton = rootView.findViewById(R.id.generateEmbeddingsButton);
        embeddingsTextView = rootView.findViewById(R.id.embeddingsTextView);
        progressBar = rootView.findViewById(R.id.progressBar);

        generateEmbeddingsButton.setOnClickListener(v -> handleGenerateEmbeddings());

        updateProcessingUI();

        return rootView;
    }

    private void handleGenerateEmbeddings() {
        String text = embedEditText.getText().toString().trim();
        if (text.isEmpty() || isProcessing) {
            return;
        }

        isProcessing = true;
        updateProcessingUI();

        MainActivity mainActivity = (MainActivity) getActivity();
        if (mainActivity != null) {
            AppState appState = mainActivity.getAppState();
            LlamaMobileSdk llamaMobileSdk = appState.getLlamaMobileSdk();
            llamaMobileSdk.generateEmbeddings(text, new LlamaMobileSdk.ResultCallback<List<Float>>() {
                @Override
                public void onSuccess(List<Float> result) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        embeddingsTextView.setText(formatEmbeddings(result));
                        updateProcessingUI();
                    });
                }

                @Override
                public void onError(Exception e) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        Toast.makeText(getContext(), "Embeddings error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        updateProcessingUI();
                    });
                }
            });
        }
    }

    private String formatEmbeddings(List<Float> embeddings) {
        StringBuilder sb = new StringBuilder();
        sb.append("Embeddings (Dimension: " + embeddings.size() + "):\n");
        int maxDisplay = Math.min(10, embeddings.size());
        for (int i = 0; i < maxDisplay; i++) {
            sb.append(String.format("%.4f", embeddings.get(i)));
            if (i < maxDisplay - 1) {
                sb.append(", ");
            }
        }
        if (embeddings.size() > maxDisplay) {
            sb.append("...");
        }
        return sb.toString();
    }

    private void updateProcessingUI() {
        if (getView() == null) return;

        progressBar.setVisibility(isProcessing ? View.VISIBLE : View.GONE);
        generateEmbeddingsButton.setEnabled(!isProcessing);
    }
}
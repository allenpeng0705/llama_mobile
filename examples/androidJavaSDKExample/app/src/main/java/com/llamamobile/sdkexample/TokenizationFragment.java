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

public class TokenizationFragment extends Fragment {

    private EditText tokenizeEditText;
    private Button tokenizeButton;
    private Button detokenizeButton;
    private TextView tokensTextView;
    private ProgressBar progressBar;

    private boolean isProcessing = false;
    private List<Integer> currentTokens;

    public TokenizationFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_tokenization, container, false);

        tokenizeEditText = rootView.findViewById(R.id.tokenizeEditText);
        tokenizeButton = rootView.findViewById(R.id.tokenizeButton);
        detokenizeButton = rootView.findViewById(R.id.detokenizeButton);
        tokensTextView = rootView.findViewById(R.id.tokensTextView);
        progressBar = rootView.findViewById(R.id.progressBar);

        tokenizeButton.setOnClickListener(v -> handleTokenize());
        detokenizeButton.setOnClickListener(v -> handleDetokenize());

        updateProcessingUI();

        return rootView;
    }

    private void handleTokenize() {
        String text = tokenizeEditText.getText().toString().trim();
        if (text.isEmpty() || isProcessing) {
            return;
        }

        isProcessing = true;
        updateProcessingUI();

        MainActivity mainActivity = (MainActivity) getActivity();
        if (mainActivity != null) {
            AppState appState = mainActivity.getAppState();
            LlamaMobileSdk llamaMobileSdk = appState.getLlamaMobileSdk();
            llamaMobileSdk.tokenize(text, false, false, new LlamaMobileSdk.ResultCallback<List<Integer>>() {
                @Override
                public void onSuccess(List<Integer> result) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        currentTokens = result;
                        tokensTextView.setText(formatTokens(result));
                        updateProcessingUI();
                    });
                }

                @Override
                public void onError(Exception e) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        Toast.makeText(getContext(), "Tokenization error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        updateProcessingUI();
                    });
                }
            });
        }
    }

    private void handleDetokenize() {
        if (currentTokens == null || currentTokens.isEmpty() || isProcessing) {
            return;
        }

        isProcessing = true;
        updateProcessingUI();

        MainActivity mainActivity = (MainActivity) getActivity();
        if (mainActivity != null) {
            AppState appState = mainActivity.getAppState();
            LlamaMobileSdk llamaMobileSdk = appState.getLlamaMobileSdk();
            llamaMobileSdk.detokenize(currentTokens, new LlamaMobileSdk.ResultCallback<String>() {
                @Override
                public void onSuccess(String result) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        tokensTextView.setText("Detokenized result: " + result);
                        updateProcessingUI();
                    });
                }

                @Override
                public void onError(Exception e) {
                    getActivity().runOnUiThread(() -> {
                        isProcessing = false;
                        Toast.makeText(getContext(), "Detokenization error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        updateProcessingUI();
                    });
                }
            });
        }
    }

    private String formatTokens(List<Integer> tokens) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tokens (").append(tokens.size()).append("): ");
        int maxDisplay = Math.min(20, tokens.size());
        for (int i = 0; i < maxDisplay; i++) {
            sb.append(tokens.get(i));
            if (i < maxDisplay - 1) {
                sb.append(", ");
            }
        }
        if (tokens.size() > maxDisplay) {
            sb.append("...");
        }
        return sb.toString();
    }

    private void updateProcessingUI() {
        if (getView() == null) return;

        progressBar.setVisibility(isProcessing ? View.VISIBLE : View.GONE);
        tokenizeButton.setEnabled(!isProcessing);
        detokenizeButton.setEnabled(!isProcessing && currentTokens != null && !currentTokens.isEmpty());
    }
}
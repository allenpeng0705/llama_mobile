package com.llamamobile.sdkexample;

import android.graphics.Color;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Switch;
import android.widget.Toast;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.llamamobile.sdk.LlamaMobileSdk;
import com.llamamobile.sdkexample.databinding.FragmentChatBinding;
import java.util.ArrayList;
import java.util.List;

public class ChatFragment extends Fragment {

    private FragmentChatBinding binding;
    private AppState appState;
    private List<Message> messages = new ArrayList<>();
    private ChatAdapter chatAdapter;
    private boolean isGenerating = false;

    private boolean useJsonGrammar = false;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        binding = FragmentChatBinding.inflate(inflater, container, false);
        appState = ((MainActivity) requireActivity()).getAppState();
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Initialize RecyclerView
        chatAdapter = new ChatAdapter(messages);
        binding.chatRecyclerView.setAdapter(chatAdapter);
        binding.chatRecyclerView.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.chatRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                // Prevent scrolling when generating
                if (isGenerating) {
                    recyclerView.scrollToPosition(messages.size() - 1);
                }
            }
        });

        // Set up send button click listener
        binding.sendButton.setOnClickListener(v -> sendMessage());

        // Update UI based on model loading status
        updateModelLoadedUI();

        // Add keyboard handling
        binding.promptEditText.setOnEditorActionListener((v, actionId, event) -> {
            sendMessage();
            return true;
        });

        // Add JSON grammar toggle if grammar is available
        if (appState.getJsonGrammar() != null) {
            // Create a toggle for JSON grammar support
            Switch grammarToggle = new Switch(requireContext());
            grammarToggle.setText("JSON Response");
            grammarToggle.setOnCheckedChangeListener((buttonView, isChecked) -> {
                useJsonGrammar = isChecked;
            });

            // Add to input area layout
            ((ViewGroup) binding.promptEditText.getParent()).addView(grammarToggle);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        // Check model status when fragment resumes
        updateModelLoadedUI();
    }

    private void sendMessage() {
        String prompt = binding.promptEditText.getText().toString().trim();
        if (prompt.isEmpty() || isGenerating) {
            return;
        }

        if (!appState.isModelLoaded()) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show();
            return;
        }

        // Clear input field
        binding.promptEditText.setText("");

        // Add user message to chat
        Message userMessage = new Message(Message.ROLE_USER, prompt);
        messages.add(userMessage);
        chatAdapter.notifyItemInserted(messages.size() - 1);
        scrollToBottom();

        // Add assistant message placeholder
        Message assistantMessage = new Message(Message.ROLE_ASSISTANT, "");
        messages.add(assistantMessage);
        chatAdapter.notifyItemInserted(messages.size() - 1);
        scrollToBottom();

        // Generate response
        generateResponse(prompt);
    }

    private void generateResponse(String prompt) {
        isGenerating = true;
        binding.sendButton.setEnabled(false);
        binding.statusTextView.setText("Generating response...");
        binding.statusTextView.setTextColor(Color.GRAY);
        binding.statusTextView.setVisibility(View.VISIBLE);

        LlamaMobileSdk.GenerationConfig.Builder configBuilder = new LlamaMobileSdk.GenerationConfig.Builder(prompt)
                .maxTokens(1024)
                .temperature(0.7f)
                .topP(0.9f);

        if (useJsonGrammar) {
            configBuilder.useGrammar(true);
            configBuilder.grammar(appState.getJsonGrammar());
        }

        appState.getLlamaMobileSdk().generateAsync(configBuilder.build(), new LlamaMobileSdk.GenerationListener() {
            @Override
            public void onGenerationStart(String startedPrompt) {
                requireActivity().runOnUiThread(() -> {
                    binding.statusTextView.setText("Generating response...");
                    binding.statusTextView.setVisibility(View.VISIBLE);
                });
            }

            @Override
            public void onTokenGenerated(String token) {
                requireActivity().runOnUiThread(() -> {
                    // Update the last message with the new token
                    if (!messages.isEmpty() && messages.get(messages.size() - 1).getRole().equals(Message.ROLE_ASSISTANT)) {
                        Message lastMessage = messages.get(messages.size() - 1);
                        Message updatedMessage = new Message(lastMessage.getRole(), lastMessage.getText() + token);
                        messages.set(messages.size() - 1, updatedMessage);
                        chatAdapter.notifyItemChanged(messages.size() - 1);
                        scrollToBottom();
                    }
                });
            }

            @Override
            public void onGenerationComplete(String result) {
                requireActivity().runOnUiThread(() -> {
                    isGenerating = false;
                    binding.sendButton.setEnabled(appState.isModelLoaded());
                    binding.statusTextView.setVisibility(View.GONE);
                });
            }

            @Override
            public void onError(Exception e) {
                requireActivity().runOnUiThread(() -> {
                    isGenerating = false;
                    binding.sendButton.setEnabled(appState.isModelLoaded());
                    binding.statusTextView.setText("Error: " + e.getMessage());
                    binding.statusTextView.setTextColor(Color.RED);
                    // Remove the empty assistant message
                    if (!messages.isEmpty() && messages.get(messages.size() - 1).getRole().equals(Message.ROLE_ASSISTANT) && messages.get(messages.size() - 1).getText().isEmpty()) {
                        messages.remove(messages.size() - 1);
                        chatAdapter.notifyItemRemoved(messages.size());
                    }
                });
            }
        });
    }

    private void updateModelLoadedUI() {
        if (appState.isModelLoaded()) {
            // Show chat interface
            binding.modelNotLoadedLayout.setVisibility(View.GONE);
            binding.chatRecyclerView.setVisibility(View.VISIBLE);
            binding.sendButton.setEnabled(true);
        } else {
            // Show model not loaded interface
            binding.modelNotLoadedLayout.setVisibility(View.VISIBLE);
            binding.chatRecyclerView.setVisibility(View.GONE);
            binding.sendButton.setEnabled(false);
        }
    }

    private void scrollToBottom() {
        binding.chatRecyclerView.scrollToPosition(messages.size() - 1);
    }
}
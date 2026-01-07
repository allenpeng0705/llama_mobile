package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.llamamobile.sdk.LlamaMobileSdk
import com.llamamobile.sdkexample.databinding.FragmentChatBinding

class ChatFragment : Fragment() {

    private lateinit var binding: FragmentChatBinding
    private lateinit var appState: AppState
    private val messages = mutableListOf<Message>()
    private lateinit var chatAdapter: ChatAdapter
    private var isGenerating = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentChatBinding.inflate(inflater, container, false)
        appState = (activity as MainActivity).appState
        return binding.root
    }

    private var useJsonGrammar = false

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Initialize RecyclerView
        chatAdapter = ChatAdapter(messages)
        binding.chatRecyclerView.apply {
            adapter = chatAdapter
            layoutManager = LinearLayoutManager(requireContext())
            addOnScrollListener(object : RecyclerView.OnScrollListener() {
                override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                    super.onScrolled(recyclerView, dx, dy)
                    // Prevent scrolling when generating
                    if (isGenerating) {
                        recyclerView.scrollToPosition(messages.size - 1)
                    }
                }
            })
        }

        // Set up send button click listener
        binding.sendButton.setOnClickListener {
            sendMessage()
        }

        // Update UI based on model loading status
        updateModelLoadedUI()

        // Add keyboard handling
        binding.promptEditText.setOnEditorActionListener { _, _, _ ->
            sendMessage()
            true
        }

        // Add JSON grammar toggle if grammar is available
        if (appState.jsonGrammar != null) {
            // Create a toggle for JSON grammar support
            val grammarToggle = android.widget.Switch(requireContext())
            grammarToggle.text = "JSON Response"
            grammarToggle.setOnCheckedChangeListener { _, isChecked ->
                useJsonGrammar = isChecked
            }

            // Add to input area layout
            (binding.promptEditText.parent as ViewGroup).addView(grammarToggle)
        }
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
    }

    private fun sendMessage() {
        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty() || isGenerating) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        // Clear input field
        binding.promptEditText.setText("")

        // Add user message to chat
        val userMessage = Message(Message.ROLE_USER, prompt)
        messages.add(userMessage)
        chatAdapter.notifyItemInserted(messages.size - 1)
        scrollToBottom()

        // Add assistant message placeholder
        val assistantMessage = Message(Message.ROLE_ASSISTANT, "")
        messages.add(assistantMessage)
        chatAdapter.notifyItemInserted(messages.size - 1)
        scrollToBottom()

        // Generate response
        generateResponse(prompt)
    }

    private fun generateResponse(prompt: String) {
        isGenerating = true
        binding.sendButton.isEnabled = false
        binding.statusTextView.text = "Generating response..."
        binding.statusTextView.setTextColor(resources.getColor(android.R.color.darker_gray, requireContext().theme))
        binding.statusTextView.visibility = View.VISIBLE

        val config = LlamaMobileSdk.GenerationConfig(
            prompt = prompt,
            maxTokens = 1024,
            temperature = 0.7f,
            topP = 0.9f,
            useGrammar = useJsonGrammar,
            grammar = if (useJsonGrammar) appState.jsonGrammar else null
        )

        appState.llamaMobileSdk.generate(config, object : LlamaMobileSdk.GenerationListener {
            override fun onGenerationStart(prompt: String) {
                requireActivity().runOnUiThread {
                    binding.statusTextView.text = "Generating response..."
                    binding.statusTextView.visibility = View.VISIBLE
                }
            }

            override fun onTokenGenerated(token: String) {
                requireActivity().runOnUiThread {
                    // Update the last message with the new token
                    if (messages.isNotEmpty() && messages.last().role == Message.ROLE_ASSISTANT) {
                        val updatedMessage = messages.last().copy(text = messages.last().text + token)
                        messages[messages.size - 1] = updatedMessage
                        chatAdapter.notifyItemChanged(messages.size - 1)
                        scrollToBottom()
                    }
                }
            }

            override fun onGenerationComplete(result: String) {
                requireActivity().runOnUiThread {
                    isGenerating = false
                    binding.sendButton.isEnabled = appState.isModelLoaded
                    binding.statusTextView.visibility = View.GONE
                }
            }

            override fun onError(error: Throwable) {
                requireActivity().runOnUiThread {
                    isGenerating = false
                    binding.sendButton.isEnabled = appState.isModelLoaded
                    binding.statusTextView.text = "Error: ${error.message}"
                    binding.statusTextView.setTextColor(resources.getColor(android.R.color.holo_red_dark, requireContext().theme))
                    // Remove the empty assistant message
                    if (messages.isNotEmpty() && messages.last().role == Message.ROLE_ASSISTANT && messages.last().text.isEmpty()) {
                        messages.removeAt(messages.size - 1)
                        chatAdapter.notifyItemRemoved(messages.size)
                    }
                }
            }
        })
    }

    private fun updateModelLoadedUI() {
        if (appState.isModelLoaded) {
            // Show chat interface
            binding.modelNotLoadedLayout.visibility = View.GONE
            binding.chatRecyclerView.visibility = View.VISIBLE
            binding.sendButton.isEnabled = true
        } else {
            // Show model not loaded interface
            binding.modelNotLoadedLayout.visibility = View.VISIBLE
            binding.chatRecyclerView.visibility = View.GONE
            binding.sendButton.isEnabled = false
        }
    }

    private fun scrollToBottom() {
        binding.chatRecyclerView.scrollToPosition(messages.size - 1)
    }
}

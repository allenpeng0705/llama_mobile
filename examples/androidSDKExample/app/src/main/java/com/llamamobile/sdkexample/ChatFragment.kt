package com.llamamobile.sdkexample

import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.core.content.ContextCompat
import android.content.Context
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import android.widget.LinearLayout
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentChatBinding
import org.json.JSONObject
import org.json.JSONException

class ChatFragment : Fragment() {

    private val TAG = "ChatFragment"
    
    private var _binding: FragmentChatBinding? = null
    private val binding get() = _binding!!
    private var appState: AppState? = null
    private val messages = mutableListOf<Message>()
    private lateinit var chatAdapter: ChatAdapter
    private var isGenerating = false

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
        _binding = FragmentChatBinding.inflate(inflater, container, false)
        return _binding!!.root
    }

    private var useJsonGrammar = false
    private var useOpenAIJSONAPI = true // Match iOS default

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Add comprehensive crash protection
        try {
            // Initialize chat with system prompt if available
            appState?.let {state ->
                if (state.systemPrompt.isNotEmpty() && messages.isEmpty()) {
                    val systemMessage = Message(Message.ROLE_SYSTEM, state.systemPrompt)
                    messages.add(systemMessage)
                }
            }
            
            // Initialize RecyclerView
            chatAdapter = ChatAdapter(messages)
            binding.chatRecyclerView.apply {
                adapter = chatAdapter
                layoutManager = LinearLayoutManager(context)
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
            // Use defensive check to prevent crashes if appState.jsonGrammar is not yet initialized
            try {
                context?.let { ctx ->
                    // Create OpenAI JSON API toggle (similar to iOS implementation)
                    val openAIJsonToggle = android.widget.Switch(ctx)
                    openAIJsonToggle.text = "Use OpenAI JSON API"
                    openAIJsonToggle.isChecked = useOpenAIJSONAPI
                    openAIJsonToggle.setOnCheckedChangeListener { _, isChecked ->
                        useOpenAIJSONAPI = isChecked
                    }

                    // Add OpenAI JSON API toggle
                    val layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    )
                    layoutParams.setMargins(0, 8, 0, 8)
                    openAIJsonToggle.layoutParams = layoutParams
                    (binding.promptEditText.parent as ViewGroup).addView(openAIJsonToggle)

                    // Add JSON grammar toggle if grammar is available
                    if (appState?.jsonGrammar != null) {
                        // Create a toggle for JSON grammar support
                        val grammarToggle = android.widget.Switch(ctx)
                        grammarToggle.text = "JSON Response"
                        grammarToggle.setOnCheckedChangeListener { _, isChecked ->
                            useJsonGrammar = isChecked
                        }

                        // Add grammar toggle
                        grammarToggle.layoutParams = layoutParams
                        (binding.promptEditText.parent as ViewGroup).addView(grammarToggle)
                    }
                }
            } catch (e: Exception) {
                // Log but don't crash if there's an issue with toggles
                e.printStackTrace()
            }
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with fragment initialization
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

    private fun sendMessage() {
        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty() || isGenerating) {
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
        binding.statusTextView.setTextColor(activity?.let { ContextCompat.getColor(it, android.R.color.darker_gray) } ?: android.graphics.Color.GRAY)
        binding.statusTextView.visibility = View.VISIBLE

        val currentAppState = appState ?: run {
            activity?.runOnUiThread {
                isGenerating = false
                binding.sendButton.isEnabled = false
                binding.statusTextView.text = "Error: App state not initialized"
                binding.statusTextView.setTextColor(activity?.let { ContextCompat.getColor(it, android.R.color.holo_red_dark) } ?: android.graphics.Color.RED)
            }
            return
        }

        // Run generation in a background thread
        Thread {
            try {
                // Build exact OpenAI API JSON format
                val sb = StringBuilder()
                sb.append("{")
                sb.append("\"model\": \"test\",")
                sb.append("\"messages\": [")
                
                // Add system message
                sb.append("{")
                sb.append("\"role\": \"system\",")
                sb.append("\"content\": \"")
                
                // Extract system message if present (should be first message)
                var systemMsg = currentAppState.systemPrompt
                var messageIndex = 0
                
                if (messages.isNotEmpty() && messages[0].role == Message.ROLE_SYSTEM) {
                    systemMsg = messages[0].text
                    messageIndex = 1
                }
                
                // Add JSON schema instruction if JSON grammar is enabled
                var fullSystemMsg = systemMsg
                if (useJsonGrammar || currentAppState.selectedGrammar != null) {
                    fullSystemMsg += "\n\nYou must respond in JSON format following this schema:\n{\"response\": \"your response here\"}"
                }
                
                // Escape special characters in system message
                sb.append(fullSystemMsg.replace("\"", "\\\"").replace("\n", "\\n"))
                sb.append("\"}")
                
                // Add conversation history
                while (messageIndex < messages.size - 1) { // -1 because last message is empty assistant placeholder
                    val currentMsg = messages[messageIndex]
                    
                    sb.append(",")
                    sb.append("{")
                    sb.append("\"role\": \"")
                    sb.append(currentMsg.role)
                    sb.append("\",")
                    sb.append("\"content\": \"")
                    // Escape special characters in message content
                    sb.append(currentMsg.text.replace("\"", "\\\"").replace("\n", "\\n"))
                    sb.append("\"}")
                    
                    messageIndex++
                }
                
                // Close messages array
                sb.append("]")
                
                // Close JSON object
                sb.append("}")
                
                val formattedPrompt = sb.toString()
                
                // Log the model input
                Log.d(TAG, "Model Input: $formattedPrompt")

                // Determine which grammar to use
                val grammarToUse = if (currentAppState.selectedGrammar != null) {
                    currentAppState.selectedGrammar
                } else if (useJsonGrammar) {
                    currentAppState.jsonGrammar
                } else {
                    null
                }
                
                // Log grammar usage for debugging
                if (grammarToUse != null) {
                    val grammarMessage = if (grammarToUse == currentAppState.jsonGrammar) {
                        "[JSON API] Using built-in JSON grammar"
                    } else {
                        "[JSON API] Using selected grammar"
                    }
                    Log.d(TAG, grammarMessage)
                } else {
                    Log.d(TAG, "[JSON API] No grammar being used")
                }
                
                val result = if (useOpenAIJSONAPI) {
                    // Use the dedicated OpenAI JSON API method
                    LlamaMobile.generateOpenAICompletion(
                        contextHandle = currentAppState.contextHandle,
                        openAIJSON = formattedPrompt,
                        grammar = grammarToUse
                    )
                } else {
                    // Use the traditional completion method
                    val params = LlamaMobile.CompletionParams(
                        prompt = formattedPrompt,
                        maxTokens = 1024,
                        temperature = 0.7f,
                        topP = 0.9f,
                        grammar = grammarToUse,
                        stopSequences = listOf("<|im_end|>") // Match iOS stop sequences
                    )
                    LlamaMobile.generateCompletion(currentAppState.contextHandle, params)
                }
                
                // Log the raw model output
                Log.d(TAG, "Model Raw Output: $result")

                // Parse the result if it's in OpenAI format
                val parsedContent = if (result != null) {
                    try {
                        // Extract the generated text from CompletionResult
                        val resultText = result.text
                        
                        // First clean up the raw result by removing extra tokens
                        var cleanedResult = resultText
                            // Remove endoftext tokens
                            .replace("<|endoftext|>", "")
                            // Remove im_end tokens
                            .replace("<|im_end|>", "")
                            // Trim whitespace
                            .trim()
                        
                        // Try multiple parsing strategies similar to iOS implementation
                        var assistantResponse = ""
                        
                        // First try to parse as JSON
                        try {
                            val json = JSONObject(cleanedResult)
                            
                            // Try format 1: choices with text field (chat_example.cpp format)
                            if (json.has("choices")) {
                                val choices = json.getJSONArray("choices")
                                if (choices.length() > 0) {
                                    val firstChoice = choices.getJSONObject(0)
                                    
                                    // Try text field first
                                    if (firstChoice.has("text")) {
                                        assistantResponse = firstChoice.getString("text").trim()
                                        Log.d(TAG, "Successfully parsed JSON with choices.text")
                                    } 
                                    // Try standard OpenAI message format
                                    else if (firstChoice.has("message")) {
                                        val message = firstChoice.getJSONObject("message")
                                        if (message.has("content")) {
                                            val content = message.get("content")
                                            
                                            // Handle both string and array content formats
                                            if (content is String) {
                                                assistantResponse = content.trim()
                                            } else if (content is org.json.JSONArray) {
                                                // Extract text from content array
                                                val textBuilder = StringBuilder()
                                                for (i in 0 until content.length()) {
                                                    val contentItem = content.getJSONObject(i)
                                                    if (contentItem.has("type") && contentItem.getString("type") == "text") {
                                                        textBuilder.append(contentItem.optString("text", ""))
                                                        textBuilder.append(" ")
                                                    }
                                                }
                                                assistantResponse = textBuilder.toString().trim()
                                            }
                                            Log.d(TAG, "Successfully parsed standard OpenAI response")
                                        }
                                    }
                                }
                            }
                            // Try format 2: single message object
                            else if (json.has("role") && json.has("content")) {
                                val content = json.get("content")
                                if (content is String) {
                                    assistantResponse = content.trim()
                                } else if (content is org.json.JSONArray) {
                                    // Extract text from content array
                                    val textBuilder = StringBuilder()
                                    for (i in 0 until content.length()) {
                                        val contentItem = content.getJSONObject(i)
                                        if (contentItem.has("type") && contentItem.getString("type") == "text") {
                                            textBuilder.append(contentItem.optString("text", ""))
                                            textBuilder.append(" ")
                                        }
                                    }
                                    assistantResponse = textBuilder.toString().trim()
                                }
                                Log.d(TAG, "Successfully parsed single message format")
                            }
                        } catch (jsonError: JSONException) {
                            // JSON parsing failed, try regex fallback
                            Log.d(TAG, "JSON parsing failed, using regex fallback: ${jsonError.message}")
                            
                            // Try to extract text field
                            val textPattern = "\"text\"\\s*:\\s*\"([^\"]+)\""
                            val textMatcher = Regex(textPattern).find(cleanedResult)
                            if (textMatcher != null) {
                                val matchGroup = textMatcher.groups[1]
                                if (matchGroup != null) {
                                    assistantResponse = matchGroup.value
                                    Log.d(TAG, "Extracted text via regex fallback")
                                }
                            }
                            // Try to extract content field if text field extraction failed
                            else if (assistantResponse.isEmpty()) {
                                val contentPattern = "\"content\"\\s*:\\s*\"([^\"]+)\""
                                val contentMatcher = Regex(contentPattern).find(cleanedResult)
                                if (contentMatcher != null) {
                                    val matchGroup = contentMatcher.groups[1]
                                    if (matchGroup != null) {
                                        assistantResponse = matchGroup.value
                                        Log.d(TAG, "Extracted content via regex fallback")
                                    }
                                }
                            }
                        }
                        
                        // If all parsing strategies failed, use the cleaned result
                        if (assistantResponse.isEmpty()) {
                            assistantResponse = cleanedResult
                            Log.d(TAG, "All parsing strategies failed, using cleaned result")
                        }
                        
                        // Normalize whitespace in the final response
                        assistantResponse.replace(Regex("\\s+"), " ").trim()
                    } catch (e: Exception) {
                        // Any other error, return cleaned result
                        Log.e(TAG, "Error parsing response: ${e.message}")
                        result.text
                            .replace("<|endoftext|>", "")
                            .replace("<|im_end|>", "")
                            .trim()
                            .replace(Regex("\\s+"), " ")
                    }
                } else {
                    null
                }
                
                // Log the parsed content that will be displayed
                Log.d(TAG, "Model Parsed Content: $parsedContent")

                activity?.runOnUiThread {
                    if (parsedContent != null) {
                        // Update the assistant message with the complete response
                        if (messages.isNotEmpty() && messages.last().role == Message.ROLE_ASSISTANT) {
                            val updatedMessage = messages.last().copy(text = parsedContent)
                            messages[messages.size - 1] = updatedMessage
                            chatAdapter.notifyItemChanged(messages.size - 1)
                            scrollToBottom()
                        }
                    } else {
                        // Handle empty result
                        activity?.let { Toast.makeText(it, "Generation failed: empty result", Toast.LENGTH_SHORT).show()}
                        // Remove the empty assistant message
                        if (messages.isNotEmpty() && messages.last().role == Message.ROLE_ASSISTANT && messages.last().text.isEmpty()) {
                            messages.removeAt(messages.size - 1)
                            chatAdapter.notifyItemRemoved(messages.size)
                        }
                    }

                    isGenerating = false
                    binding.sendButton.isEnabled = currentAppState.isModelLoaded
                    binding.statusTextView.visibility = View.GONE
                }
            } catch (e: Exception) {
                activity?.runOnUiThread {
                    isGenerating = false
                    binding.sendButton.isEnabled = currentAppState.isModelLoaded
                    binding.statusTextView.text = "Error: ${e.message}"
                    binding.statusTextView.setTextColor(activity?.let { ContextCompat.getColor(it, android.R.color.holo_red_dark) } ?: android.graphics.Color.RED)
                    // Remove the empty assistant message
                    if (messages.isNotEmpty() && messages.last().role == Message.ROLE_ASSISTANT && messages.last().text.isEmpty()) {
                        messages.removeAt(messages.size - 1)
                        chatAdapter.notifyItemRemoved(messages.size)
                    }
                }
            }
        }.start()
    }

    private fun updateModelLoadedUI() {
        if (!isAdded) return  // Don't update UI if fragment not attached
        
        val modelLoaded = appState?.isModelLoaded ?: false
        try {
            if (modelLoaded) {
                // Show chat interface
                binding.modelNotLoadedLayout.visibility = View.GONE
                binding.chatRecyclerView.visibility = View.VISIBLE
                binding.sendButton.isEnabled = true
            } else {
                // Show model not loaded interface - ensure it's visible
                binding.modelNotLoadedLayout.visibility = View.VISIBLE
                binding.chatRecyclerView.visibility = View.GONE
                binding.sendButton.isEnabled = false
                // Force the modelNotLoadedLayout to be brought to the front
                binding.modelNotLoadedLayout.bringToFront()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun scrollToBottom() {
        try {
            binding.chatRecyclerView.scrollToPosition(messages.size - 1)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

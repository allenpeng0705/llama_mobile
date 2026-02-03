package com.llamamobile

import com.llamamobile.LlamaMobile.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

/**
 * Kotlin extensions and DSL for LlamaMobile Java API
 *
 * This file provides Kotlin-friendly APIs, DSL builders, and coroutine support
 * that work with the Java LlamaMobile class.
 */

/**
 * DSL builder for TTSOptions
 */
fun ttsOptions(block: TTSOptions.Builder.() -> Unit): TTSOptions =
    TTSOptions.Builder().apply(block).build()

/**
 * DSL builder for DownloadParams
 */
fun downloadParams(repoId: String, filename: String, destinationPath: String, block: DownloadParams.Builder.() -> Unit): DownloadParams =
    DownloadParams.Builder(repoId, filename, destinationPath).apply(block).build()

/**
 * Extension function to add a user message to chat messages
 */
fun List<ChatMessage>.user(content: String): List<ChatMessage> =
    this + ChatMessage("user", content)

/**
 * Extension function to add an assistant message to chat messages
 */
fun List<ChatMessage>.assistant(content: String): List<ChatMessage> =
    this + ChatMessage("assistant", content)

/**
 * Extension function to add a system message to chat messages
 */
fun List<ChatMessage>.system(content: String): List<ChatMessage> =
    this + ChatMessage("system", content)

/**
 * Extension function to add a tool message to chat messages
 */
fun List<ChatMessage>.tool(
    content: String,
    toolName: String? = null,
    toolCallId: String? = null
): List<ChatMessage> =
    this + ChatMessage("tool", content, null, toolName, toolCallId)



/**
 * Extension function to check if result is error
 */
fun <S, E> Result<S, E>.isError(): Boolean = this.isFailure()

/**
 * Extension function to get value or throw error
 */
fun <S, E> Result<S, E>.getOrThrow(): S {
    if (this.isSuccess()) {
        return this.value
    }
    throw RuntimeException(this.error?.toString() ?: "Unknown error")
}

/**
 * Coroutine-based completion generation
 */
suspend fun LlamaMobile.generateCompletionAsync(
    contextHandle: Long,
    params: CompletionParams
): LlamaMobile.CompletionResult? =
    withContext(Dispatchers.IO) {
        try {
            generateCompletion(contextHandle, params)
        } catch (e: Exception) {
            null
        }
    }

/**
 * Coroutine-based chat completion
 */
suspend fun LlamaMobile.chatAsync(
    contextHandle: Long,
    messages: List<ChatMessage>,
    maxTokens: Int = 1024
): LlamaMobile.CompletionResult? {
    val params = CompletionParams.chat(messages, maxTokens)
    return withContext(Dispatchers.IO) {
        try {
            generateCompletion(contextHandle, params)
        } catch (e: Exception) {
            null
        }
    }
}

/**
 * Coroutine-based streaming completion
 */
suspend fun LlamaMobile.streamCompletionAsync(
    contextHandle: Long,
    params: CompletionParams,
    onToken: (String) -> Unit
): LlamaMobile.CompletionResult? {
    return withContext(Dispatchers.IO) {
        val paramsWithCallback = if (params.tokenCallback != null) {
            params
        } else {
            CompletionParams(
                params.prompt,
                params.temperature,
                params.maxTokens,
                params.nThreads,
                params.seed,
                params.topK,
                params.topP,
                params.minP,
                params.typicalP,
                params.penaltyLastN,
                params.penaltyRepeat,
                params.penaltyFreq,
                params.penaltyPresent,
                params.mirostat,
                params.mirostatTau,
                params.mirostatEta,
                params.isIgnoreEos,
                params.nProbs,
                params.grammar,
                params.stopSequences,
                params.mediaPaths,
                TokenCallback { token ->
                    onToken(token)
                    true
                },
                params.chatMessages,
                params.isUseJsonResponse,
                params.jsonSchema,
                params.tools,
                params.isParallelToolCalls,
                params.toolChoice
            )
        }
        generateCompletion(contextHandle, paramsWithCallback)
    }
}

/**
 * Coroutine-based TTS generation
 */
suspend fun LlamaMobile.generateSpeechAsync(
    contextHandle: Long,
    text: String,
    options: TTSOptions? = null
): LlamaMobile.SpeechResult? =
    withContext(Dispatchers.IO) {
        try {
            val result = generateSpeech(contextHandle, text, options ?: TTSOptions.Builder().build())
            if (result.isSuccess()) result.value else null
        } catch (e: Exception) {
            null
        }
    }

/**
 * Coroutine-based model download
 */
suspend fun LlamaMobile.downloadModelAsync(
    params: DownloadParams,
    progressCallback: LlamaMobile.DownloadProgressCallback? = null
): LlamaMobile.DownloadResult = withContext(Dispatchers.IO) {
    try {
        downloadModel(params, progressCallback) ?: LlamaMobile.DownloadResult(false, null, "Download failed: unknown error")
    } catch (e: Exception) {
        LlamaMobile.DownloadResult(false, null, "Download failed: ${e.message}")
    }
}

/**
 * Extension function to create ChatMessage from JSON
 */
fun chatMessageFromJson(json: String): ChatMessage {
    val jsonObject = JSONObject(json)
    val role = jsonObject.optString("role")
    val content = jsonObject.optString("content")
    val reasoningContent = jsonObject.optString("reasoning_content").let { if (it.isEmpty()) null else it }
    val toolName = jsonObject.optString("tool_name").let { if (it.isEmpty()) null else it }
    val toolCallId = jsonObject.optString("tool_call_id").let { if (it.isEmpty()) null else it }
    return ChatMessage(role, content, reasoningContent, toolName, toolCallId)
}

/**
 * Extension function to convert ChatMessage to JSON
 */
fun ChatMessage.toJson(): String {
    val jsonObject = JSONObject()
    jsonObject.put("role", role)
    jsonObject.put("content", content)
    if (reasoningContent != null) {
        jsonObject.put("reasoning_content", reasoningContent)
    }
    if (toolName != null) {
        jsonObject.put("tool_name", toolName)
    }
    if (toolCallId != null) {
        jsonObject.put("tool_call_id", toolCallId)
    }
    return jsonObject.toString()
}

package com.llamamobile.sdkexample

data class Message(val role: String, val text: String) {
    companion object {
        const val ROLE_USER = "user"
        const val ROLE_ASSISTANT = "assistant"
    }
}

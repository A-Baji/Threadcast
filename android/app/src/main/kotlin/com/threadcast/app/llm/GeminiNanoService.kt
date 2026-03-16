package com.threadcast.app.llm

// TODO: Implement Gemini Nano via ML Kit GenAI Prompt API
// Dependency: implementation("com.google.mlkit:genai-prompt:1.0.0-beta1")
// See CLAUDE.md -- Android: Gemini Nano via ML Kit GenAI Prompt API
class GeminiNanoService {
    suspend fun isAvailable(): Boolean = false  // TODO
    suspend fun generateTranscript(prompt: String): String = ""  // TODO
    fun release() {}
}
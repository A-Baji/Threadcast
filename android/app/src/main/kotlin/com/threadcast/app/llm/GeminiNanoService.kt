package com.threadcast.app.llm

import com.google.mlkit.genai.FeatureStatus
import com.google.mlkit.genai.GenAiException
import com.google.mlkit.genai.GenerativeModel
import com.google.mlkit.genai.generateContentRequest
import com.google.mlkit.genai.textPart

class GeminiNanoService {
    // Correct entry point for the GenerativeModel client
    private val generativeModel: GenerativeModel = GenerativeModel.getClient()

    suspend fun isAvailable(): Boolean =
        generativeModel.checkStatus() == FeatureStatus.AVAILABLE

    suspend fun generateTranscript(promptText: String): String {
        if (generativeModel.checkStatus() != FeatureStatus.AVAILABLE) {
            throw GenAiException("MODEL_UNAVAILABLE")
        }

        // generateContentRequest now requires a TextPart as the first argument
        val request = generateContentRequest(textPart(promptText)) {
            config {
                temperature = 0.7f
            }
        }
        
        val response = generativeModel.generateContent(request)
        return response.text ?: throw GenAiException("MODEL_RETURNED_EMPTY")
    }

    fun release() = generativeModel.close()
}
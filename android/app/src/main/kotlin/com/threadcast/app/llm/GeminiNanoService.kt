package com.threadcast.app.llm

import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.generateContentRequest
import com.google.mlkit.genai.prompt.TextPart

class GeminiNanoService {
    private val generativeModel: GenerativeModel by lazy { Generation.getClient() }

    suspend fun checkStatus(): Any? = generativeModel.checkStatus()

    suspend fun isAvailable(): Boolean = runCatching {
        matchesStatus(checkStatus(), statusAvailable)
    }.getOrDefault(false)

    suspend fun generateTranscript(prompt: String): String {
        val status = checkStatus()
        if (!matchesStatus(status, statusAvailable)) {
            throw IllegalStateException("MODEL_UNAVAILABLE: ${describeStatus(status)}")
        }

        val request = generateContentRequest(TextPart(prompt)) {}
        val response = generativeModel.generateContent(request)
        return extractResponseText(response)
            ?: throw IllegalStateException("GENERATION_FAILED: MODEL_RETURNED_EMPTY")
    }

    fun release() = generativeModel.close()

    private fun matchesStatus(status: Any?, expected: String): Boolean {
        val label = describeStatus(status)
        return label == expected || loadFeatureStatusConstant(expected) == status
    }

    private fun describeStatus(status: Any?): String {
        if (status == null) return "null"

        runCatching {
            val nameMethod = status.javaClass.methods
                .firstOrNull { method -> method.name == "name" && method.parameterCount == 0 }
            val value = nameMethod?.invoke(status) as? String
            if (!value.isNullOrBlank()) {
                return value
            }
        }

        return featureStatusFieldNames().firstOrNull { fieldName ->
            loadFeatureStatusConstant(fieldName) == status
        } ?: status.toString()
    }

    private fun loadFeatureStatusConstant(fieldName: String): Any? =
        runCatching {
            Class.forName(featureStatusClassName)
                .getField(fieldName)
                .get(null)
        }.getOrNull()

    private fun featureStatusFieldNames(): List<String> =
        runCatching {
            Class.forName(featureStatusClassName)
                .fields
                .filter { field -> java.lang.reflect.Modifier.isStatic(field.modifiers) }
                .map { field -> field.name }
        }.getOrDefault(emptyList())

    private fun extractResponseText(response: Any): String? {
        readStringProperty(response, "text")?.let { return it }

        val candidates = readValue(response, "candidates") as? Iterable<*> ?: return null
        for (candidate in candidates) {
            if (candidate == null) continue

            readStringProperty(candidate, "text")?.let { return it }

            val content = readValue(candidate, "content") ?: continue
            readStringProperty(content, "text")?.let { return it }

            val parts = readValue(content, "parts") as? Iterable<*> ?: continue
            val text = parts
                .mapNotNull { part -> part?.let { readStringProperty(it, "text") } }
                .joinToString(separator = "")
                .ifBlank { null }
            if (text != null) {
                return text
            }
        }

        return null
    }

    private fun readStringProperty(target: Any, propertyName: String): String? =
        readValue(target, propertyName) as? String

    private fun readValue(target: Any, propertyName: String): Any? {
        val getterName = "get" + propertyName.replaceFirstChar { it.uppercase() }

        runCatching {
            target.javaClass.methods
                .firstOrNull { method -> method.name == getterName && method.parameterCount == 0 }
                ?.invoke(target)
        }.getOrNull()?.let { return it }

        return runCatching {
            target.javaClass.fields
                .firstOrNull { field -> field.name == propertyName }
                ?.get(target)
        }.getOrNull()
    }

    private companion object {
        const val featureStatusClassName = "com.google.mlkit.genai.prompt.FeatureStatus"
        const val statusAvailable = "AVAILABLE"
    }
}
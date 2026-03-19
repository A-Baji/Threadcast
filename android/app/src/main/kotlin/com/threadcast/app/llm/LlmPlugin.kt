package com.threadcast.app.llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class LlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val service = GeminiNanoService()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var activeJob: Job? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.threadcast.app/llm")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                scope.launch {
                    try {
                        val available = service.isAvailable()
                        withContext(Dispatchers.Main) { result.success(available) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("STATUS_CHECK_FAILED", e.message, null)
                        }
                    }
                }
            }

            "generateTranscript" -> {
                val prompt = call.argument<String>("prompt")
                if (prompt.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "Missing prompt", null)
                    return
                }

                activeJob?.cancel()
                activeJob = scope.launch {
                    try {
                        val transcript = service.generateTranscript(prompt)
                        withContext(Dispatchers.Main) { result.success(transcript) }
                    } catch (e: CancellationException) {
                        withContext(Dispatchers.Main) {
                            result.error("CANCELLED", "Generation cancelled", null)
                        }
                    } catch (e: Exception) {
                        val code = when {
                            e.message?.contains("BACKGROUND", ignoreCase = true) == true -> "BACKGROUND_BLOCKED"
                            e.message?.contains("MODEL_UNAVAILABLE", ignoreCase = true) == true -> "MODEL_UNAVAILABLE"
                            e.message?.contains("CONTEXT", ignoreCase = true) == true -> "CONTEXT_TOO_LONG"
                            else -> "GENERATION_FAILED"
                        }
                        withContext(Dispatchers.Main) {
                            result.error(code, e.message, null)
                        }
                    } finally {
                        activeJob = null
                    }
                }
            }

            "cancelGeneration" -> {
                activeJob?.cancel()
                activeJob = null
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activeJob?.cancel()
        service.release()
        scope.cancel()
    }
}
package com.threadcast.app.llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

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
                        withContext(Dispatchers.Main) {
                            result.error("GENERATION_FAILED", e.message, null)
                        }
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
        scope.cancel()
        service.release()
    }
}
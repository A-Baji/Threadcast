package com.threadcast.app.llm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// TODO: Implement full LLM platform channel
// See CLAUDE.md -- Android: Gemini Nano via ML Kit GenAI Prompt API
class LlmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private val service = GeminiNanoService()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.threadcast.app/llm")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable"         -> result.success(false)
            "generateTranscript"  -> result.error("NOT_IMPLEMENTED", "TODO", null)
            "cancelGeneration"    -> result.success(null)
            else                  -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        service.release()
    }
}
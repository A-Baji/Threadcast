import Flutter
import UIKit

// TODO: Implement full LLM platform channel
// See CLAUDE.md -- iOS: Foundation Models Framework
class LlmPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.threadcast.app/llm",
            binaryMessenger: registrar.messenger()
        )
        let instance = LlmPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(false)  // TODO: check SystemLanguageModel.default.availability
        case "generateTranscript":
            result(FlutterError(code: "NOT_IMPLEMENTED", message: "TODO", details: nil))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
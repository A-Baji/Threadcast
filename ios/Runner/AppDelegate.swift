import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register LLM platform channel
        if let controller = window?.rootViewController as? FlutterViewController {
            LlmPlugin.register(with: controller.registrar(forPlugin: "LlmPlugin")!)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

import Flutter
import UIKit
import BackgroundTasks

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

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.threadcast.app.generate",
            using: nil
        ) { task in
            guard #available(iOS 18.0, *),
                  let continuedTask = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            continuedTask.expirationHandler = {
                continuedTask.setTaskCompleted(success: false)
            }
            continuedTask.setTaskCompleted(success: true)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
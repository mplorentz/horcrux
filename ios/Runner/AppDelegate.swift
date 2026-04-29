import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Required so foreground presentation and tap callbacks reach flutter_local_notifications
    // (FlutterAppDelegate forwards UNUserNotificationCenterDelegate to registered plugins).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Method channel for triggering APNs registration on demand. The Firebase
    // plugin only calls registerForRemoteNotifications once at launch, so when
    // the user re-enables notifications in Settings after a previous denial we
    // need to re-register to obtain an APNs token.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "horcrux/push",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "registerForRemoteNotifications":
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            result(nil)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    // Method channel for triggering APNs registration on demand; mirrors the
    // iOS AppDelegate. Needed because the Firebase plugin only registers once
    // at launch and won't re-register after a permission state change.
    if let controller = NSApp.windows.first?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "horcrux/push",
        binaryMessenger: controller.engine.binaryMessenger
      )
      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "registerForRemoteNotifications":
          DispatchQueue.main.async {
            NSApplication.shared.registerForRemoteNotifications()
            result(nil)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}

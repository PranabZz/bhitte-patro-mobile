import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "group.bhittepatroapp", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { (call, result) in
        if call.method == "updateCalendarWidget" {
          if let args = call.arguments as? [String: Any] {
            let userDefaults = UserDefaults(suiteName: "group.bhittepatroapp")
            for (key, value) in args {
              userDefaults?.set(value, forKey: key)
            }
            userDefaults?.synchronize()
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments were not a dictionary", details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

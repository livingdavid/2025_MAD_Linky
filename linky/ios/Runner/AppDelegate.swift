import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self  // OK: inherits conformance
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      print("알림 권한 granted? \(granted)")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let defaults = UserDefaults(suiteName: "group.com.linky")
    defaults?.set(url.absoluteString, forKey: "sharedLink")
    defaults?.synchronize()
    return super.application(app, open: url, options: options)
  }
}

// 🎯 notification delegate method은 확장으로 분리
extension AppDelegate /*: UNUserNotificationCenterDelegate */ {
    override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let link = response.notification.request.content.userInfo["link"] as? String {
      UserDefaults(suiteName: "group.com.linky")?.set(link, forKey: "sharedLink")
    }
    completionHandler()
  }
}

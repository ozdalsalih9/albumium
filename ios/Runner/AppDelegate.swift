import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  let albumium = AlbumiumPlatformBridge()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    UNUserNotificationCenter.current().delegate = self
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    albumium.register(messenger: engineBridge.applicationRegistrar.messenger())
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    if response.notification.request.identifier.hasPrefix(MemoryCalendar.prefix) {
      albumium.openMemory(response.notification.request.content.userInfo)
      completionHandler()
    } else { super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler) }
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if notification.request.identifier.hasPrefix(MemoryCalendar.prefix) { completionHandler([.banner, .sound]) }
    else { super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler) }
  }
}

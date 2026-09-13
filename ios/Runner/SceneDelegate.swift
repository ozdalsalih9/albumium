import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    let bridge = (UIApplication.shared.delegate as? AppDelegate)?.albumium
    for context in connectionOptions.urlContexts { bridge?.receive(context.url) }
    if let response = connectionOptions.notificationResponse { bridge?.openMemory(response.notification.request.content.userInfo) }
  }
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts { (UIApplication.shared.delegate as? AppDelegate)?.albumium.receive(context.url) }
  }
}

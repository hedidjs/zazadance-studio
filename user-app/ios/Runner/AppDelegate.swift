import Flutter
import UIKit
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure Google Sign-In
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      if let plist = NSDictionary(contentsOfFile: path) {
        if let clientId = plist["CLIENT_ID"] as? String {
          let configuration = GIDConfiguration(clientID: clientId)
          GIDSignIn.sharedInstance.configuration = configuration
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url) || super.application(app, open: url, options: options)
  }
}

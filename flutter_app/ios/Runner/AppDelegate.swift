import Flutter
import UIKit
import FirebaseCore
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase first
    FirebaseApp.configure()
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up remote notification for Firebase Phone Auth
    // This enables silent APNs for phone verification on real devices
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs token registration - required for Firebase Phone Auth
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Pass device token to Firebase Auth for phone authentication
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    
    // Also call super to ensure Flutter plugins receive the token
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle failed registration
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
    // This is expected on iOS Simulator since APNs is not available
    // Firebase Auth will fall back to reCAPTCHA verification
  }
  
  // Handle incoming remote notifications for Firebase Auth verification
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification notification: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Let Firebase Auth handle the notification if it's for phone auth
    if Auth.auth().canHandleNotification(notification) {
      completionHandler(.noData)
      return
    }
    
    // Otherwise, pass to Flutter
    super.application(
      application,
      didReceiveRemoteNotification: notification,
      fetchCompletionHandler: completionHandler
    )
  }
  
  // Handle URL schemes for reCAPTCHA verification
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Check if Firebase Auth can handle the URL (for reCAPTCHA callback)
    if Auth.auth().canHandle(url) {
      return true
    }
    
    // Otherwise, pass to Flutter for handling
    return super.application(app, open: url, options: options)
  }
}
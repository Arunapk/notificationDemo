//
//  AppDelegate.swift
//  notifyDemo
//
//  Created by Arunpandikumar MAC Book Pro on 04/11/24.
//

import UIKit
import CoreData
import UserNotifications
import FirebaseMessaging
import FirebaseCore
import CallKit
import AVFoundation
import PushKit

let callController = CXCallController()


@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        
        //MARK: NOTIFICATION PERMISSION REQUEST
        self.registerForPushNotification(application)

        //MARK: REMOTE NOTIFICATION REGISTERATION
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")
//            self.fcmRegTokenMessage.text  = "Remote FCM registration token: \(token)"
          }
        }
        
        let pushRegistry = PKPushRegistry(queue: .main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        
        return true
    }
    
    //MARK: SETUP CALL KIT
    func setupCallKit() {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.phoneNumber, .emailAddress]
        let provider = CXProvider(configuration: providerConfiguration)
        provider.setDelegate(self, queue: nil)
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }

    
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "notifyDemo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    
    
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

//MARK: REMOTE NOTIFICATION (FCM)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        debugPrint("tokenString -->\(tokenString)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    //MARK: Register for push notification
    func registerForPushNotification(_ application: UIApplication)  {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound]) // Options: .alert, .badge, etc.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        debugPrint(response)
    }
}


//MARK: VOIP NOTIFICATION
extension AppDelegate: CXProviderDelegate, PKPushRegistryDelegate {
        func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
            // Register push credentials with server
            print(pushCredentials.token)
            //         let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
            let deviceTokenString = pushCredentials.token.hexString
            print("PUSH KIT TOKEN \(deviceTokenString)")
//            UserDefaultModule().setPushToken(fcm_token: deviceTokenString)
//            if (UserDefaultModule().getFCMToken() != nil && UserDefaultModule().getPushToken() != nil){
//                Utility.shared.registerPushServices()
//            }
        }

        func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
            // Handle incoming VoIP push notification
            completion()
        }
    
    func providerDidReset(_ provider: CXProvider) {
        debugPrint("providerDidReset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // Handle starting a call
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // Handle ending a call
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // Handle answering a call
        action.fulfill()
    }
    
    
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

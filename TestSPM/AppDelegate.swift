//
//  AppDelegate.swift
//  TestSPM
//
//  Created by Skyler Tanner on 4/30/21.
//

import UIKit
import MarketingCloudSDK


@main
class AppDelegate: UIResponder,
                   UIApplicationDelegate,
                   MarketingCloudSDKLocationDelegate,
                   MarketingCloudSDKURLHandlingDelegate,
                   MarketingCloudSDKEventDelegate,
                   UNUserNotificationCenterDelegate {
    
    let appID = "[PROD-APNS appId value from MobilePush app admin]"
    let accessToken = "[PROD-APNS accessToken value from MobilePush app admin]"
    let appEndpoint = "[PROD-APNS app endpoint value from MobilePush app admin]"
    let mid = "[PROD-APNS account MID value from MobilePush app admin]"
    
    // Define features of MobilePush your app will use.
    let inbox = true
    let location = true
    let pushAnalytics = true
    let piAnalytics = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        let builder = MarketingCloudSDKConfigBuilder()
            .sfmc_setApplicationId(appID)
            .sfmc_setAccessToken(accessToken)
            .sfmc_setMarketingCloudServerUrl(appEndpoint)
            .sfmc_setMid(mid)
            .sfmc_setDelayRegistration(untilContactKeyIsSet: true)
            .sfmc_setInboxEnabled(inbox as NSNumber)
            .sfmc_setLocationEnabled(location as NSNumber)
            .sfmc_setAnalyticsEnabled(pushAnalytics as NSNumber)
            .sfmc_build()!
        
        return configurePushSDK(config: builder)
    }
    
    func configurePushSDK(config: [AnyHashable: Any]) -> Bool {
        var success = false
        
        do {
            try MarketingCloudSDK.sharedInstance().sfmc_configure(with: config)
            success = true
        } catch let error as NSError {
            // Errors returned from configuration will be in the NSError parameter and can be used to determine
            // if you've implemented the SDK correctly.
            
            let configErrorString = String(format: "MarketingCloudSDK sfmc_configure failed with error = %@", error)
            print(configErrorString)
        }
        
        
        if success {
            // The SDK has been fully configured and is ready for use!
            MarketingCloudSDK.sharedInstance().sfmc_setURLHandlingDelegate(self)
            // turn on logging for debugging.  Not recommended for production apps.
            MarketingCloudSDK.sharedInstance().sfmc_setDebugLoggingEnabled(true)
            
            // Great place for setting the contact key, tags and attributes since you know the SDK is setup and ready.
            MarketingCloudSDK.sharedInstance().sfmc_setContactKey("TestKey")
            MarketingCloudSDK.sharedInstance().sfmc_addTag("Hiking Supplies")
            MarketingCloudSDK.sharedInstance().sfmc_addTag("Sports")
            MarketingCloudSDK.sharedInstance().sfmc_setAttributeNamed("FavoriteTeamName", value: "favoriteTeamName")
            MarketingCloudSDK.sharedInstance().sfmc_startWatchingLocation()
            
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    // set the delegate if needed then ask if we are authorized - the delegate must be set here if used
                    UNUserNotificationCenter.current().delegate = self
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
                        if error == nil {
                            if granted == true {
                                // we are authorized to use notifications, request a device token for remote notifications
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                
                                // Support notification categories
                                let exampleAction = UNNotificationAction(identifier: "App", title: "Open App", options: [UNNotificationActionOptions.foreground])
                                let appCategory = UNNotificationCategory(identifier: "Open App", actions: [exampleAction], intentIdentifiers: [] as? [String] ?? [String](), options: [])
                                let categories = Set<AnyHashable>([appCategory])
                                UNUserNotificationCenter.current().setNotificationCategories(categories as? Set<UNNotificationCategory> ?? Set<UNNotificationCategory>())
                            }
                        }
                    })
                }
                else {
                    let type: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.alert, UIUserNotificationType.sound]
                    let setting = UIUserNotificationSettings(types: type, categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(setting)
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return success
    }
    
    func sfmc_shouldShowLocationMessage(_ message: [AnyHashable : Any], forRegion region: [AnyHashable : Any]) -> Bool {
        return true
    }
    
    func sfmc_handle(_ url: URL, type: String) {
        
        return
    }
    
    // MobilePush SDK: REQUIRED IMPLEMENTATION
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MarketingCloudSDK.sharedInstance().sfmc_setDeviceToken(deviceToken)
    }
    
    // MobilePush SDK: REQUIRED IMPLEMENTATION
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    // MobilePush SDK: REQUIRED IMPLEMENTATION
    /** This delegate method offers an opportunity for applications with the "remote-notification" background mode to fetch appropriate new data in response to an incoming remote notification. You should call the fetchCompletionHandler as soon as you're finished performing that operation, so the system can accurately estimate its power and data cost.
     This method will be invoked even if the application was launched or resumed because of the remote notification. The respective delegate methods will be invoked first. Note that this behavior is in contrast to application:didReceiveRemoteNotification:, which is not called in those cases, and which will not be invoked if this method is implemented. **/
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        MarketingCloudSDK.sharedInstance().sfmc_setNotificationUserInfo(userInfo)
        completionHandler(.newData)
    }
    
    
    // MobilePush SDK: REQUIRED IMPLEMENTATION
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    @objc(userNotificationCenter:willPresentNotification:withCompletionHandler:) @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.banner)
    }
    
    // this method will be called by iOS to tell the MarketingCloudSDK to update location and proximity messages. This will only be called if [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:
    // has been set to a value other than UIApplicationBackgroundFetchIntervalNever and Background App Refresh is enabled.
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        MarketingCloudSDK.sharedInstance().sfmc_refresh(fetchCompletionHandler: completionHandler)
    }
    
    @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:) func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // tell the MarketingCloudSDK about the notification
        MarketingCloudSDK.sharedInstance().sfmc_setNotificationRequest(response.notification.request)
        
        // Check your notification custom actions
        if (response.actionIdentifier == "App") {
            print("Its Working!")
            
            let userInfo = response.notification.request.content.userInfo
            let someValue = userInfo["CustomKey1"] as? String ?? "someValue is nil"
            print(someValue)
        }
        
        completionHandler()
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


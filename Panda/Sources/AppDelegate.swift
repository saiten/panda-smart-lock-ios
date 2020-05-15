//
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import Common
import RxSwift
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()

    var window: UIWindow?

    private lazy var mainViewController: MainViewController = {
        let viewController = MainViewController.configure()
        return viewController
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        setAppearance()
        
        let navigationController = UINavigationController(rootViewController: mainViewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        
        SmartLockDeviceManager.shared.start()
        
        // パンダの検知を通知
        SmartLockDeviceManager.shared.currentDevice
            .filter { $0 != nil }
            .subscribe(onNext: { [weak self] device in
                let center = UNUserNotificationCenter.current()
                if let _ = device {
                    // 前面のときは通知しない
                    if UIApplication.shared.applicationState != .active {
                        let content = UNMutableNotificationContent()
                        content.title = "🐼が近くにあります"
                        content.sound = UNNotificationSound.default
                        content.categoryIdentifier = "lock-category"
                        
                        let request = UNNotificationRequest(identifier: "found-panda", content: content, trigger: nil)
                        center.add(request)
                    }
                    self?.updatePandaLocation()
                } else {
                    // 通知済みを削除
                    center.removeAllDeliveredNotifications()
                }
            })
            .disposed(by: disposeBag)
        
        self.setupNotofication()
        return true
    }
    
    private func setupNotofication() {
        let unlockAction = UNNotificationAction(identifier: "unlock", title: "Unlock", options: [.destructive])
        let lockAction = UNNotificationAction(identifier: "lock", title: "Lock", options: [])
        
        let category = UNNotificationCategory(identifier: "lock-category",
                                              actions: [lockAction, unlockAction],
                                              intentIdentifiers: [],
                                              options: [])
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([category])
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    private func setAppearance() {
        UINavigationBar.appearance().tintColor = Asset.Colors.babyPowder.color
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Asset.Colors.babyPowder.color,
            NSAttributedString.Key.font: FontFamily.ExoticAgent.regular.font(size: 20)!
        ]
        UINavigationBar.appearance().barTintColor = Asset.Colors.stone.color
        UIBarButtonItem.appearance().setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: Asset.Colors.babyPowder.color,
            NSAttributedString.Key.font: FontFamily.ExoticAgent.regular.font(size: 16)!
        ], for: .normal)
    }
    
    private func updatePandaLocation() {
        locationManager.startUpdatingLocation()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "unlock":
            mainViewController.unlock()
        case "lock":
            mainViewController.lock()
        default:
            break
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        let region = CLCircularRegion(center: currentLocation.coordinate, radius: 5, identifier: "found-panda")
        region.notifyOnExit = false
        region.notifyOnEntry = true
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "🐼が近くにあります"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "lock-category"
        
        let request = UNNotificationRequest(identifier: "found-panda", content: content, trigger: trigger)
        center.add(request)

        // 一度取得できればOK
        locationManager.stopUpdatingLocation()
    }
}

/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIApplication delegate.
 */

import UIKit
import HealthKit
import FirebaseAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        //self.requestAccessToHealthKit()
        WatchSessionManager.sharedManager.startSession()
        return true
    }
    
    private func requestAccessToHealthKit() {
        let healthStore = HKHealthStore()
        
        let allTypes = Set([HKObjectType.workoutType(),
                            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
                            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
                            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                print(error ?? "Error occured requesting access to HealthKit")
            }
        }
    }
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        let healthStore = HKHealthStore()
        healthStore.handleAuthorizationForExtension { (success, error) -> Void in
            self.requestAccessToHealthKit()
        }
    }
}


/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Interface controller for the configuration screen.
 */

import WatchKit
import Foundation
import HealthKit
import UserNotifications

class ConfigurationInterfaceController: WKInterfaceController {
    // MARK: Properties
    
    var selectedParticipantNumber: Int
    
    var participantNumbers: [Int] = []
    
    // MARK: IB Outlets
    
    @IBOutlet var participantNumberPicker: WKInterfacePicker!
    
//    @IBOutlet var locationTypePicker: WKInterfacePicker!
    
    // MARK: Initialization
    
    override init() {
        participantNumbers += 1...70
        selectedParticipantNumber = participantNumbers[0]
        super.init()
    }
    
    // MARK: Interface Controller Overrides
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let participantNumber = UserDefaults.standard.integer(forKey: "participantNumber")
        if (participantNumber != 0){
            let workoutConfiguration = HKWorkoutConfiguration()
            WKInterfaceController.reloadRootControllers(withNames: ["WorkoutInterfaceController"], contexts: [workoutConfiguration])
        }
        
        let participantNumberPickerItems: [WKPickerItem] = participantNumbers.map {number in
            let pickerItem = WKPickerItem()
            pickerItem.title = String(number)
            return pickerItem
        }

        participantNumberPicker.setItems(participantNumberPickerItems)
        
        setTitle("AccurateSteps")
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
    
    private func requestAllowNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if !granted {
                print(error ?? "Error occured requesting notifications")
            } else {
                 DispatchQueue.main.async { [] in
                    WKInterfaceController.reloadRootControllers(withNames: ["WorkoutInterfaceController"], contexts: nil)
                }
            }
        }
    }

    // MARK: IB Actions
    
    @IBAction func participantNumberPickerSelectedItemChanged(value: Int) {
        selectedParticipantNumber = participantNumbers[value]
    }
    
    @IBAction func didTapStartButton() {
        // Create workout configuration
//        let workoutConfiguration = HKWorkoutConfiguration()
//        workoutConfiguration.activityType = selectedActivityType
//        workoutConfiguration.locationType = selectedLocationType
        UserDefaults.standard.set(selectedParticipantNumber, forKey: "participantNumber")
        UserDefaults.standard.set(Date(), forKey: "stepLastDate")
        UserDefaults.standard.set(Date(), forKey: "heartLastDate")
        UserDefaults.standard.set("0", forKey: "stepCount")
        //requestAccessToHealthKit()
        requestAllowNotifications()
        // Pass configuration to next interface controller
        WKInterfaceController.reloadRootControllers(withNames: ["WorkoutInterfaceController"], contexts: nil)
    }
    
}

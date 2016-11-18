/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Interface controller for the configuration screen.
 */

import WatchKit
import Foundation
import HealthKit

class ConfigurationInterfaceController: WKInterfaceController {
    // MARK: Properties
    
    var selectedParticipantNumber: Int
    
//    var selectedLocationType: HKWorkoutSessionLocationType
    
    let participantNumbers: [Int] = [1, 2, 3]
    
//    let locationTypes: [HKWorkoutSessionLocationType] = [.unknown, .indoor, .outdoor]
    
    // MARK: IB Outlets
    
    @IBOutlet var participantNumberPicker: WKInterfacePicker!
    
//    @IBOutlet var locationTypePicker: WKInterfacePicker!
    
    // MARK: Initialization
    
    override init() {
        selectedParticipantNumber = participantNumbers[0]
//        selectedLocationType = locationTypes[0]
        
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
        
        // Populate the activity type picker
        let participantNumberPickerItems: [WKPickerItem] = participantNumbers.map {number in
            let pickerItem = WKPickerItem()
            pickerItem.title = String(number)
            return pickerItem
        }
//        let activityTypePickerItems: [WKPickerItem] = activityTypes.map {type in
//            let pickerItem = WKPickerItem()
//            pickerItem.title = format(activityType: type)
//            return pickerItem
//        }
        participantNumberPicker.setItems(participantNumberPickerItems)
        
        // Populate the location type picker
//        let locationTypePickerItems: [WKPickerItem] = locationTypes.map {type in
//            let pickerItem = WKPickerItem()
//            pickerItem.title = format(locationType: type)
//            return pickerItem
//        }
//        locationTypePicker.setItems(locationTypePickerItems)
        
        setTitle("Speedy Sloth")
    }

    // MARK: IB Actions
    
    @IBAction func participantNumberPickerSelectedItemChanged(value: Int) {
        selectedParticipantNumber = participantNumbers[value]
    }
        
//    @IBAction func locationTypePickerSelectedItemChanged(value: Int) {
//        selectedLocationType = locationTypes[value]
//    }
    
    @IBAction func didTapStartButton() {
        // Create workout configuration
        let workoutConfiguration = HKWorkoutConfiguration()
//        workoutConfiguration.activityType = selectedActivityType
//        workoutConfiguration.locationType = selectedLocationType
        UserDefaults.standard.set(selectedParticipantNumber, forKey: "participantNumber")
        UserDefaults.standard.set(Date(), forKey: "stepLastDate")
        UserDefaults.standard.set(Date(), forKey: "heartLastDate")
        UserDefaults.standard.set("0", forKey: "stepCount")
        // Pass configuration to next interface controller
        WKInterfaceController.reloadRootControllers(withNames: ["WorkoutInterfaceController"], contexts: [workoutConfiguration])
    }
    
}

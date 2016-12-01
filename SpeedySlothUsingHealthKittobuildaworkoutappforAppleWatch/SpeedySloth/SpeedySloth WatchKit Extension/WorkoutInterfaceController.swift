/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Interface controller for the active workout screen.
 */

import WatchKit
import Foundation
import HealthKit
import ClockKit
import WatchConnectivity
import UserNotifications

class WorkoutInterfaceController: WKInterfaceController, WKExtensionDelegate, UNUserNotificationCenterDelegate {
    // MARK: Properties
    
    let timeBetweenRefresh = 5 * 60.0
    
    let healthStore = HKHealthStore()
    
    var activeDataQueries = [HKQuery]()
    
    var totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: 0)
    
    var session : WCSession!

    // MARK: IBOutlets
    
    @IBOutlet var modifiedStepCountLabel: WKInterfaceLabel!

    // MARK: Interface Controller Overrides
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKExtension.shared().delegate = self
        setTotalSteps(steps: modToActualSteps(modified: Double(UserDefaults.standard.string(forKey: "stepCount")!)!))
        updateLabels()
        let future = Date(timeIntervalSinceNow: timeBetweenRefresh)
        scheduleReset()
        scheduleBackgroundRefresh(preferredDate: future)
    }
    override func willActivate() {
        refreshStepCount()
        WatchSessionManager.sharedManager.startSession()
        super.willActivate()
    }
    
    override func didAppear() {
        refreshStepCount()
    }
    // MARK: Totals
    
    public func totalSteps() -> Double {
        return totalStepCount.doubleValue(for: HKUnit.count())
    }
    
    public func totalModSteps() -> Double {
        let partNum = UserDefaults.standard.integer(forKey: "participantNumber")
        if (partNum % 3 == 0){
            return self.totalSteps() * 1.4
        } else if (partNum % 3 == 1){
            return self.totalSteps() * 0.6
        } else {
            return self.totalSteps()
        }
        
    }
    
    public func modToActualSteps(modified: Double) -> Double {
        let partNum = UserDefaults.standard.integer(forKey: "participantNumber")
        if (partNum % 3 == 0){
            return modified / 1.4
        } else if (partNum % 3 == 1){
            return modified / 0.6
        } else {
            return modified
        }
        
    }
    
    private func setTotalSteps(steps: Double) {
        totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
    }
    
    // MARK: Convenience
    
    func updateLabels() {
        modifiedStepCountLabel.setText(format(steps: totalModSteps()))
    }
    
    func sendDataToServer(stepCount: Double?, heartRate: Double?, date:Date!) {
        let scriptUrl = "https://steps-4a070.firebaseio.com/users/9.json"
        let uid = String(format:"%d", UserDefaults.standard.integer(forKey: "participantNumber"))
        let timeString = String(format:"%f", (date.timeIntervalSince1970))
        print(timeString)
        var stepCountString = ""
        var heartRateString = ""
        var urlWithParams = ""
        var bodyString = ""
        if (stepCount != nil) {
            stepCountString = String(format: "%.0f", stepCount!)
            urlWithParams = scriptUrl //+ "?stepCount=\(stepCountString)&uid=9"
            bodyString = "{\"stepCount\" : \(stepCountString), \"uid\" : \(uid), \"time\" : \(timeString)}"
            print(bodyString)
        } else {
            heartRateString = String(format: "%.0f", heartRate!)
            urlWithParams = scriptUrl //+ "?heartRate=\(heartRateString)&uid=9"
            bodyString = "{\"heartRate\" : \(heartRateString), \"uid\" : \(uid), \"time\" : \(timeString)}"
            print(bodyString)
        }

        let myUrl = URL(string: urlWithParams);
        
        var request = URLRequest(url:myUrl!);
        request.httpBody = bodyString.data(using: .utf8)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString)")
        }
        
        task.resume()
    }
    
    func notifyUser() {
        let content = UNMutableNotificationContent()
        
        content.title = "Goal Progress"
        content.body = String(format: "Another 1000 steps! Current step count: %0.f", self.totalModSteps())
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest.init(identifier: String(format:"%f", (Date().timeIntervalSince1970)), content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if (error != nil) {
                print(error ?? "Error requesting single notification")
            } else {
                print ("Update notification scheduled")
            }
        }
    }
    
    func scheduleReset() {
        let content = UNMutableNotificationContent()
        
        content.title = "Steps for the Day"
        content.body = String(format: "Total steps for today: %0.f", self.totalModSteps())
        content.sound = nil
        
        var date = DateComponents()
        date.hour = 23
        date.minute = 59
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        let calendar = Calendar.current
        let identifierDate = calendar.startOfDay(for: Date())
        
        let request = UNNotificationRequest.init(identifier: String(format:"Reset%f", (identifierDate.timeIntervalSince1970)), content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if (error != nil) {
                print(error ?? "Error requesting single notification")
            } else {
                print ("Reset notification scheduled")
            }
            
        }
    }
    
    func refreshStepCount(){
        let endDate = Date()
        let calendar = NSCalendar.current
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let stepStartDate = calendar.startOfDay(for: endDate)
        let stepDatePredicate = HKQuery.predicateForSamples(withStart: stepStartDate, end: endDate, options: .strictStartDate)
        let stepPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[stepDatePredicate, devicePredicate])
        
        guard let stepSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** This method should never fail ***")
        }
        
        let stepQuery = HKStatisticsQuery(quantityType: stepSampleType,
                                          quantitySamplePredicate: stepPredicate,
                                          options: .cumulativeSum) { query, result, error in
                                            
                                            guard let quantity = result?.sumQuantity() else {
                                                print("An error occured fetching the user's step count data. The error was: \(error?.localizedDescription)");
                                                return
                                            }
                                            
                                            let unit = HKUnit.count()
                                            let totalSteps = quantity.doubleValue(for: unit)
                                            
                                            DispatchQueue.main.async { [weak self] in
                                                guard let strongSelf = self else { return }
                                                strongSelf.setTotalSteps(steps: totalSteps)
                                                strongSelf.updateLabels()
                                                UserDefaults.standard.set(String(format: "%.0f", strongSelf.totalModSteps()), forKey: "stepCount")
                                                let complicationServer = CLKComplicationServer.sharedInstance()
                                                for complication in complicationServer.activeComplications! {
                                                    complicationServer.reloadTimeline(for: complication)
                                                }
                                            }
                                            
        }
        
        healthStore.execute(stepQuery)

    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        let future = Date(timeIntervalSinceNow: self.timeBetweenRefresh)
        self.scheduleBackgroundRefresh(preferredDate: future)
        
        var stepsFinished = false
        var heartFinished = false
        let endDate = Date()
        let calendar = NSCalendar.current
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        guard let heartSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            fatalError("*** This method should never fail ***")
        }
        
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let heartStartDate = UserDefaults.standard.object(forKey: "heartLastDate") as! Date
        let heartDatePredicate = HKQuery.predicateForSamples(withStart: heartStartDate, end: endDate, options: .strictStartDate)
        let heartPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[heartDatePredicate, devicePredicate])
        
        let heartQuery = HKSampleQuery(sampleType: heartSampleType, predicate: heartPredicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                fatalError("An error occured fetching the user's heart rate data. The error was: \(error?.localizedDescription)");
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                var latest: Date?
                latest = nil
                for sample in samples {
                    print(sample)
                    print ("start:")
                    print (sample.startDate)
                    print ("end:")
                    print (sample.endDate)
                    if (latest == nil || latest?.compare(sample.endDate) == ComparisonResult.orderedAscending) {
                        latest = sample.endDate
                    }
                    let newHeart = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    print(newHeart)
                    strongSelf.sendDataToServer(stepCount: nil, heartRate: newHeart, date:sample.startDate)
                }
                if (latest != nil){
                    UserDefaults.standard.set(latest, forKey: "heartLastDate")
                    print("NEXT HEART START DATE")
                    print(latest!)
                }

                if (stepsFinished) {
                    for task : WKRefreshBackgroundTask in backgroundTasks {
                        task.setTaskCompleted()
                    }
                } else {
                    heartFinished = true
                }
            }
        }
        
        guard let stepSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** This method should never fail ***")
        }
        let stepStartDate = calendar.startOfDay(for: endDate)
        let stepDatePredicate = HKQuery.predicateForSamples(withStart: stepStartDate, end: endDate, options: .strictStartDate)
        let stepPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[stepDatePredicate, devicePredicate])
        
        let stepQuery = HKStatisticsQuery(quantityType: stepSampleType,
                                          quantitySamplePredicate: stepPredicate,
                                          options: .cumulativeSum) { query, result, error in
                                            
                                            guard let quantity = result?.sumQuantity() else {
                                                print("An error occured fetching the user's step count data. The error was: \(error?.localizedDescription)");
                                                return
                                            }
                                            
                                            let unit = HKUnit.count()
                                            let totalSteps = quantity.doubleValue(for: unit)
                                            print("TOTAL STEPS FOR DAY:")
                                            print(totalSteps)
                                            
                                            DispatchQueue.main.async { [weak self] in
                                                guard let strongSelf = self else { return }
                                                let prevSteps = strongSelf.totalModSteps()
                                                strongSelf.setTotalSteps(steps: totalSteps)
                                                strongSelf.updateLabels()
                                                if (Int(strongSelf.totalModSteps() / 1000)  > Int(prevSteps / 1000)) {
                                                    strongSelf.notifyUser()
                                                }
                                                UserDefaults.standard.set(String(format: "%.0f", strongSelf.totalModSteps()), forKey: "stepCount")
                                                let complicationServer = CLKComplicationServer.sharedInstance()
                                                for complication in complicationServer.activeComplications! {
                                                    complicationServer.reloadTimeline(for: complication)
                                                }
                                                _ = WatchSessionManager.sharedManager.transferUserInfo(userInfo: ["stepCount" : strongSelf.totalSteps() as AnyObject, "uid":UserDefaults.standard.integer(forKey: "participantNumber") as AnyObject])
                                                strongSelf.sendDataToServer(stepCount: strongSelf.totalSteps(), heartRate: nil, date: endDate)
                                                
                                                if (heartFinished) {
                                                    for task : WKRefreshBackgroundTask in backgroundTasks {
                                                        task.setTaskCompleted()
                                                    }
                                                } else {
                                                    stepsFinished = true
                                                }
                                            }
                                            
        }
        
        healthStore.execute(stepQuery)
        healthStore.execute(heartQuery)
    }
    
    func scheduleBackgroundRefresh(preferredDate: Date?) {
        if let preferredDate = preferredDate {
            let completion: (Error?) -> Void = { (error) in
                // Handle error if needed
                if (error == nil) {
                    print("Successfully scheduled background task")
                } else {
                    print(error ?? "Error scheduling next background refresh")
                }
            }
            WKExtension.shared().scheduleBackgroundRefresh(
                withPreferredDate: preferredDate,
                userInfo: nil,
                scheduledCompletion: completion
            )
        }
    }


}


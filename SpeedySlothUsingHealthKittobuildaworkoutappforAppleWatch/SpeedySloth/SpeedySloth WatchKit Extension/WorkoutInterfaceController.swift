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
    // MARK: Properties,
    
    let timeBetweenRefresh = 5 * 60.0 // CHANGE TO SOMETHING MORE REASONABLE LATER
    
    let healthStore = HKHealthStore()
    
    var activeDataQueries = [HKQuery]()
    
    var queryStartDate : Date?
    
    var totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: 0)
    
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    
    var isPaused = false
    
    var stepIncrements = 1
    
    var session : WCSession!

    // MARK: IBOutlets
    
    @IBOutlet var modifiedStepCountLabel: WKInterfaceLabel!
    
    @IBOutlet var pauseResumeButton : WKInterfaceButton!
//
    @IBOutlet var markerLabel: WKInterfaceLabel!

    // MARK: Interface Controller Overrides
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
//        let center = UNUserNotificationCenter.current()
//        center.delegate = self
        WKExtension.shared().delegate = self
        let now = Date()
        let calendar = NSCalendar.current
        queryStartDate = calendar.startOfDay(for: now)
        setTotalSteps(steps: modToActualSteps(modified: Double(UserDefaults.standard.string(forKey: "stepCount")!)!))
        updateLabels()
        // startAccumulatingData(startDate: queryStartDate!)
        let future = Date(timeIntervalSinceNow: timeBetweenRefresh)
        scheduleReset()
        scheduleBackgroundRefresh(preferredDate: future)
    }
    override func willActivate() {
        //refreshStepCount()
        WatchSessionManager.sharedManager.startSession()
        super.willActivate()
    }
    
    override func didAppear() {
        refreshStepCount()
    }
    // MARK: Totals
    
    
//    func applicationDidFinishLaunching() {
//        let center = UNUserNotificationCenter.current()
//        center.delegate = self
//        return
//    }
//
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        let identifier = response.notification.request.identifier
//        print(identifier)
//        if identifier.hasPrefix("Reset"){
//            UserDefaults.standard.set("0", forKey: "stepCount")
//            let complicationServer = CLKComplicationServer.sharedInstance()
//            for complication in complicationServer.activeComplications! {
//                complicationServer.extendTimeline(for: complication)
//            }
//        }
//        completionHandler()
//        
//    }
//
//    func setupObserverQueries(){
//        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
//            fatalError("*** This method should never fail ***")
//        }
//        
//        let stepObserverQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) {
//            query, completionHandler, error in
//            
//            if error != nil {
//                print("*** An error occured while setting up the stepCount observer. \(error?.localizedDescription) ***")
//                abort()
//            }
//            
//            // Take whatever steps are necessary to update your app's data and UI
//            // This may involve executing other queries
//            self.updateStepCount()
//            
//            // If you have subscribed for background updates you must call the completion handler here.
//            completionHandler()
//        }
//        
//        healthStore.execute(stepObserverQuery)
//    }
    
//    func updateStepCount() {
//        let calendar = NSCalendar.current
//        
//        let endDate = Date()
//        let startDate = calendar.startOfDay(for: endDate)
//        
//        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
//        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
//        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
//        
//        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
//            fatalError("*** This method should never fail ***")
//        }
//        let query = HKStatisticsQuery(quantityType: sampleType,
//                                      quantitySamplePredicate: queryPredicate,
//                                      options: .cumulativeSum) { query, result, error in
//                                        
//                                        guard let quantity = result?.sumQuantity() else {
//                                            fatalError("An error occured fetching the user's step count data. The error was: \(error?.localizedDescription)");
//                                        }
//                                        
//                                        let unit = HKUnit.count()
//                                        let totalSteps = quantity.doubleValue(for: unit)
//                                        print("TOTAL STEPS FOR DAY:")
//                                        print(totalSteps)
//                                        
//                                        DispatchQueue.main.async { [weak self] in
//                                            guard let strongSelf = self, !strongSelf.isPaused else { return }
//                                            let prevSteps = strongSelf.totalModSteps()
//                                            strongSelf.setTotalSteps(steps: totalSteps)
//                                            strongSelf.updateLabels()
//                                            if (Int(strongSelf.totalModSteps() / 1000)  > Int(prevSteps / 1000)) {
//                                                strongSelf.notifyUser()
//                                            }
//                                            UserDefaults.standard.set(String(format: "%.0f", strongSelf.totalModSteps()), forKey: "stepCount")
//                                            let complicationServer = CLKComplicationServer.sharedInstance()
//                                            for complication in complicationServer.activeComplications! {
//                                                complicationServer.reloadTimeline(for: complication)
//                                            }
//                                            _ = WatchSessionManager.sharedManager.transferUserInfo(userInfo: ["stepCount" : strongSelf.totalSteps() as AnyObject, "uid":UserDefaults.standard.integer(forKey: "participantNumber") as AnyObject])
//                                            strongSelf.sendDataToServer(stepCount: strongSelf.totalSteps(), heartRate: nil, date: endDate)
//                                        }
//                                        
//        }
//        
//        healthStore.execute(query)
//    }
//
    
    private func totalCalories() -> Double {
        return totalEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
    }
    
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
    
    private func totalMeters() -> Double {
        return totalDistance.doubleValue(for: HKUnit.meter())
    }
    
    
    private func setTotalCalories(calories: Double) {
        totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
    }
    
    private func setTotalSteps(steps: Double) {
        totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
    }
    
    private func setTotalMeters(meters: Double) {
        totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: meters)
    }
    
    // MARK: IB Actions
    
//    @IBAction func didTapPauseResumeButton() {
//        if let session = workoutSession {
//            switch session.state {
//            case .running:
//                healthStore.pause(_: session)
//            case .paused:
//                healthStore.resumeWorkoutSession(_: session)
//            default:
//                break
//            }
//        }
//    }
//    
//    @IBAction func didTapStopButton() {
//        workoutEndDate = Date()
//        
//        // End the Workout Session
//        healthStore.end(workoutSession!)
//    }
//    
//    @IBAction func didTapMarkerButton() {
//        let markerEvent = HKWorkoutEvent(type: .marker, date: Date())
//        workoutEvents.append(markerEvent)
//        notifyEvent(markerEvent)
//    }
    
    // MARK: Convenience
    
    func updateLabels() {
        modifiedStepCountLabel.setText(format(steps: totalModSteps()))
    }
    
//    func updateState() {
//        if let session = workoutSession {
//            switch session.state {
//                case .running:
//                    setTitle("Active Workout")
//                    parentConnector.send(state: "running")
//                    pauseResumeButton.setTitle("Pause")
//                
//                case .paused:
//                    setTitle("Paused Workout")
//                    parentConnector.send(state: "paused")
//                    pauseResumeButton.setTitle("Resume")
//                
//                case .notStarted, .ended:
//                    setTitle("Workout")
//                    parentConnector.send(state: "ended")
//            }
//        }
//    }
    
    func notifyEvent(_: HKWorkoutEvent) {
        weak var weakSelf = self

        DispatchQueue.main.async {
            weakSelf?.markerLabel.setAlpha(1)
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter (deadline: .now()+1) {
                weakSelf?.markerLabel.setAlpha(0)
            }
        }
    }
    
    func vibWatch() {
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    // MARK: Data Queries
    
    func startAccumulatingData(startDate: Date) {
        // startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        // startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
        startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier.stepCount)
        //startTimer()
    }
    
    func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        print (quantityTypeIdentifier)
        let datePredicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: nil, options: .strictStartDate) // REPLACED OPTIONS WITH [] IF NOT WORKING
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let updateHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { query, samples, deletedObjects, queryAnchor, error in
            self.process(samples: samples, quantityTypeIdentifier: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
                                          predicate: queryPredicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)
        
        activeDataQueries.append(query)
    }
    
    func process(samples: [HKSample]?, quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        print(samples)
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, !strongSelf.isPaused else { return }
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                for sample in quantitySamples {
                    if quantityTypeIdentifier == HKQuantityTypeIdentifier.distanceWalkingRunning {
                        let newMeters = sample.quantity.doubleValue(for: HKUnit.meter())
                        strongSelf.setTotalMeters(meters: strongSelf.totalMeters() + newMeters)
                    } else if quantityTypeIdentifier == HKQuantityTypeIdentifier.activeEnergyBurned {
                        let newKCal = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                        strongSelf.setTotalCalories(calories: strongSelf.totalCalories() + newKCal)
                    } else if quantityTypeIdentifier == HKQuantityTypeIdentifier.stepCount {
                        let newSteps = sample.quantity.doubleValue(for: HKUnit.count())
                        strongSelf.setTotalSteps(steps: strongSelf.totalSteps() + newSteps)
                        
                        UserDefaults.standard.set(String(format: "%.0f", strongSelf.totalModSteps()), forKey: "stepCount")
                        
                        let complicationServer = CLKComplicationServer.sharedInstance()
                        for complication in complicationServer.activeComplications! {
                            complicationServer.reloadTimeline(for: complication)
                        }
                        _ = WatchSessionManager.sharedManager.transferUserInfo(userInfo: ["stepCount" : strongSelf.totalSteps() as AnyObject, "uid":UserDefaults.standard.integer(forKey: "participantNumber") as AnyObject])
                        strongSelf.sendDataToServer(stepCount: strongSelf.totalSteps(), heartRate: nil, date: Date())
                        if (strongSelf.totalSteps() >= Double(strongSelf.stepIncrements * 10)){
                            strongSelf.stepIncrements += 1
                            strongSelf.vibWatch()
                        }
                    }
                }
                
                strongSelf.updateLabels()
            }
        }
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

        // Create NSURL Ibject
        let myUrl = URL(string: urlWithParams);
        
        // Creaste URL Request
        var request = URLRequest(url:myUrl!);
//        let bodyString = "{\"stepCount\" : \(stepCount), \"uid\" : 9}"
        request.httpBody = bodyString.data(using: .utf8)
        // Set request HTTP method to GET. It could be POST as well
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            // Check for error
            if error != nil
            {
                print("error=\(error)")
                return
            }
            
            // Print out response string
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString)")
            
            
            // Convert server json response to NSDictionary
//            do {
//                if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
//                    
//                    // Print out dictionary
//                    print(convertedJsonIntoDict)
//                    
//                    // Get value by key
//                    let firstNameValue = convertedJsonIntoDict["userName"] as? String
//                    print(firstNameValue!)
//                    
//                }
//            } catch let error as NSError {
//                print(error.localizedDescription)
//            }
            
        }
        
        task.resume()
    }
    
    func stopAccumulatingData() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }
        
        activeDataQueries.removeAll()
    }
    
    func pauseAccumulatingData() {
        DispatchQueue.main.sync {
            isPaused = true
        }
    }
    
    func resumeAccumulatingData() {
        DispatchQueue.main.sync {
            isPaused = false
        }
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
                                                guard let strongSelf = self, !strongSelf.isPaused else { return }
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

//        let startDate = calendar.startOfDay(for: endDate)
        
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
                guard let strongSelf = self, !strongSelf.isPaused else { return }
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
        
        //let stepStartDate = UserDefaults.standard.object(forKey: "stepLastDate") as! Date
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
                                                guard let strongSelf = self, !strongSelf.isPaused else { return }
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
                    print("successfully scheduled background task, use the crown to send the app to the background and wait for handle:BackgroundTasks to fire.")
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
    
    func heartRateQuery() {
        
    }


}


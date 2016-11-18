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

class WorkoutInterfaceController: WKInterfaceController, WKExtensionDelegate {
    // MARK: Properties,
    
    let healthStore = HKHealthStore()
    
    var activeDataQueries = [HKQuery]()
    
//    let parentConnector = ParentConnector()
    
    var queryStartDate : Date?
    
//    var workoutEndDate : Date?
    
    var totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: 0)
    
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    
//    var workoutEvents = [HKWorkoutEvent]()
    
//    var metadata = [String: AnyObject]()
//    
//    var timer : Timer?
    
    var isPaused = false
    
    var stepIncrements = 1
    
    var session : WCSession!

    // MARK: IBOutlets
    
    @IBOutlet var modifiedStepCountLabel: WKInterfaceLabel!
    
    @IBOutlet var actualStepCountLabel: WKInterfaceLabel!
    
    @IBOutlet var pauseResumeButton : WKInterfaceButton!
//
    @IBOutlet var markerLabel: WKInterfaceLabel!

    // MARK: Interface Controller Overrides
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WKExtension.shared().delegate = self
        let now = Date()
        let calendar = NSCalendar.current
        queryStartDate = calendar.startOfDay(for: now)
        setTotalSteps(steps: modToActualSteps(modified: Double(UserDefaults.standard.string(forKey: "stepCount")!)!))
        updateLabels()
        // startAccumulatingData(startDate: queryStartDate!)
        let future = Date(timeIntervalSinceNow: 20.0)
        scheduleBackgroundRefresh(preferredDate: future)
    }
    override func willActivate() {
        WatchSessionManager.sharedManager.startSession()
        super.willActivate()
    }
    // MARK: Totals
    
    
    
//    override func applicationDidEnterBackground() {
//        let now = Date()
//        let future = now.addingTimeInterval(10)
//        scheduleBackgroundRefresh(preferredDate: future)
//    }
    
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
        actualStepCountLabel.setText(format(steps: totalSteps()))
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
                        WatchSessionManager.sharedManager.transferUserInfo(userInfo: ["stepCount" : strongSelf.totalSteps() as AnyObject, "uid":UserDefaults.standard.integer(forKey: "participantNumber") as AnyObject])
                        strongSelf.sendDataToServer(stepCount: strongSelf.totalSteps(), heartRate: nil)
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
    
    func sendDataToServer(stepCount: Double?, heartRate: Double?) {
        let scriptUrl = "https://steps-4a070.firebaseio.com/users/9.json"
        var stepCountString = ""
        var heartRateString = ""
        var urlWithParams = ""
        var bodyString = ""
        if (stepCount != nil) {
            stepCountString = String(format: "%.0f", stepCount!)
            urlWithParams = scriptUrl //+ "?stepCount=\(stepCountString)&uid=9"
            bodyString = "{\"stepCount\" : \(stepCountString), \"uid\" : 9}"
        } else {
            heartRateString = String(format: "%.0f", heartRate!)
            urlWithParams = scriptUrl //+ "?heartRate=\(heartRateString)&uid=9"
            bodyString = "{\"heartRate\" : \(heartRateString), \"uid\" : 9}"
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
    
    
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        var stepsFinished = false
        var heartFinished = false
        let endDate = Date()
        let calendar = NSCalendar.current
//        let startDate = calendar.startOfDay(for: endDate)
        let stepStartDate = UserDefaults.standard.object(forKey: "stepLastDate") as! Date
        let heartStartDate = UserDefaults.standard.object(forKey: "heartLastDate") as! Date
        print("STEP START DATE")
        print(stepStartDate)
        print("HEART START DATE")
        print(heartStartDate)
        
        guard let stepSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** This method should never fail ***")
        }
        guard let heartSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            fatalError("*** This method should never fail ***")
        }
        let predicate = HKQuery.predicateForSamples(withStart: stepStartDate, end: endDate, options: .strictStartDate)
        let heartPredicate = HKQuery.predicateForSamples(withStart: heartStartDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let heartQuery = HKSampleQuery(sampleType: heartSampleType, predicate: heartPredicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(error?.localizedDescription)");
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
                    let newHeart = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.second()))
                    print(newHeart)
                    strongSelf.sendDataToServer(stepCount: nil, heartRate: newHeart)
                }
                if (latest != nil){
                    UserDefaults.standard.set(latest, forKey: "heartLastDate")
                    print("NEXT HEART START DATE")
                    print(latest!)
                }
//                UserDefaults.standard.set(String(format: "%.0f", strongSelf.totalModSteps()), forKey: "stepCount")
                
//                WatchSessionManager.sharedManager.transferUserInfo(userInfo: ["stepCount" : strongSelf.totalSteps() as AnyObject, "uid":UserDefaults.standard.integer(forKey: "participantNumber") as AnyObject])
                
//                UserDefaults.standard.set(latest, forKey: "lastDate")
                
//                let future = Date(timeIntervalSinceNow: 20.0)
//                strongSelf.scheduleBackgroundRefresh(preferredDate: future)
                if (stepsFinished) {
                    for task : WKRefreshBackgroundTask in backgroundTasks {
                        task.setTaskCompleted()
                    }
                } else {
                    heartFinished = true
                }
            }
        }

        
        
        let stepQuery = HKSampleQuery(sampleType: stepSampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(error?.localizedDescription)");
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self, !strongSelf.isPaused else { return }
                var addedSteps = 0.0
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
                    let newSteps = sample.quantity.doubleValue(for: HKUnit.count())
                    print(newSteps)
                    addedSteps += newSteps
                }
                if ((latest != nil) && !calendar.isDate(latest!, inSameDayAs: stepStartDate)){
                    strongSelf.setTotalSteps(steps: 0.0)
                }
                strongSelf.setTotalSteps(steps: strongSelf.totalSteps() + addedSteps)
                UserDefaults.standard.set(String(format: "%.0f", strongSelf.totalModSteps()), forKey: "stepCount")
                let complicationServer = CLKComplicationServer.sharedInstance()
                for complication in complicationServer.activeComplications! {
                    complicationServer.reloadTimeline(for: complication)
                }
                
                WatchSessionManager.sharedManager.transferUserInfo(userInfo: ["stepCount" : strongSelf.totalSteps() as AnyObject, "uid":UserDefaults.standard.integer(forKey: "participantNumber") as AnyObject])
                strongSelf.sendDataToServer(stepCount: strongSelf.totalSteps(), heartRate: nil)
                if (strongSelf.totalSteps() >= Double(strongSelf.stepIncrements * 10)){
                    strongSelf.stepIncrements += 1
                    strongSelf.vibWatch()
                }
                if (latest != nil){
                    UserDefaults.standard.set(latest, forKey: "stepLastDate")
                    print("NEXT STEP START DATE")
                    print(latest!)
                }
                
                let future = Date(timeIntervalSinceNow: 20.0)
                strongSelf.scheduleBackgroundRefresh(preferredDate: future)
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


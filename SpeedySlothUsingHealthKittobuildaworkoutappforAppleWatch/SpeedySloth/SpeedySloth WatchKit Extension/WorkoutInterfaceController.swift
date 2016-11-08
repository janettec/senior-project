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

class WorkoutInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    // MARK: Properties
    
    let healthStore = HKHealthStore()
    
    var workoutSession : HKWorkoutSession?
    
    var activeDataQueries = [HKQuery]()
    
    let parentConnector = ParentConnector()
    
    var workoutStartDate : Date?
    
    var workoutEndDate : Date?
    
    var totalStepCount = HKQuantity(unit: HKUnit.count(), doubleValue: 0)
    
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    
    var workoutEvents = [HKWorkoutEvent]()
    
    var metadata = [String: AnyObject]()
    
    var timer : Timer?
    
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
        workoutStartDate = Date()
        startAccumulatingData(startDate: workoutStartDate!)
        // Start a workout session with the configuration
//        if let workoutConfiguration = context as? HKWorkoutConfiguration {
//            do {
//                workoutConfiguration.activityType = .walking
//                //workoutConfiguration.locationType = .indoor
//                workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
//                workoutSession?.delegate = self
//                
//                //workoutStartDate = Date()
//                
//                //healthStore.start(workoutSession!)
//            } catch {
//                // ...
//            }
//        }
    }
    
    override func willActivate() {
        WatchSessionManager.sharedManager.startSession()
        super.willActivate()
    }
    // MARK: Totals
    
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
    
    @IBAction func didTapPauseResumeButton() {
        if let session = workoutSession {
            switch session.state {
            case .running:
                healthStore.pause(_: session)
            case .paused:
                healthStore.resumeWorkoutSession(_: session)
            default:
                break
            }
        }
    }
    
    @IBAction func didTapStopButton() {
        workoutEndDate = Date()
        
        // End the Workout Session
        healthStore.end(workoutSession!)
    }
    
    @IBAction func didTapMarkerButton() {
        let markerEvent = HKWorkoutEvent(type: .marker, date: Date())
        workoutEvents.append(markerEvent)
        notifyEvent(markerEvent)
    }
    
    // MARK: Convenience
    
    func updateLabels() {
        modifiedStepCountLabel.setText(format(steps: totalModSteps()))
        actualStepCountLabel.setText(format(steps: totalSteps()))
    }
    
    func updateState() {
        if let session = workoutSession {
            switch session.state {
                case .running:
                    setTitle("Active Workout")
                    parentConnector.send(state: "running")
                    pauseResumeButton.setTitle("Pause")
                
                case .paused:
                    setTitle("Paused Workout")
                    parentConnector.send(state: "paused")
                    pauseResumeButton.setTitle("Resume")
                
                case .notStarted, .ended:
                    setTitle("Workout")
                    parentConnector.send(state: "ended")
            }
        }
    }
    
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
//        let sampleType =
//            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
//        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: [])//.strictStartDate)
//        let query = HKObserverQuery(sampleType: sampleType!, predicate: datePredicate) {
//            query, completionHandler, error in
//            
//            if error != nil {
//                
//                // Perform Proper Error Handling Here...
//                print("*** An error occured while setting up the stepCount observer. \(error?.localizedDescription) ***")
//                abort()
//            }
//            
//            // Take whatever steps are necessary to update your app's data and UI
//            // This may involve executing other queries
//            print("STEPS UPDATED")
//            
//            // If you have subscribed for background updates you must call the completion handler here.
//            // completionHandler()
//        }
        
        //healthStore.execute(query)
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: [])//.strictStartDate)
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
                        strongSelf.sendDataToServer(stepCount: strongSelf.totalSteps())
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
    
    func sendDataToServer(stepCount: Double) {
        let scriptUrl = "https://steps-4a070.firebaseio.com/users/9.json"
        let stepCount = String(format: "%.0f", stepCount)
        let urlWithParams = scriptUrl //+ "?stepCount=\(stepCount)&uid=9"
        // Create NSURL Ibject
        let myUrl = URL(string: urlWithParams);
        
        // Creaste URL Request
        var request = URLRequest(url:myUrl!);
        let bodyString = "{\"stepCount\" : \(stepCount), \"uid\" : 9}"
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
        stopTimer()
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
 
    // MARK: Timer code

    func startTimer() {
        print("start timer")
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(timerDidFire),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    func timerDidFire(timer: Timer) {
        print("timer")
        updateLabels()
    }

    func stopTimer() {
        timer?.invalidate()
    }
    
    // MARK: HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout session did fail with error: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        workoutEvents.append(event)
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        switch toState {
            case .running:
                if fromState == .notStarted {
                    startAccumulatingData(startDate: workoutStartDate!)
                } else {
                    resumeAccumulatingData()
                }
            
            case .paused:
                pauseAccumulatingData()
            
            case .ended:
                stopAccumulatingData()
                saveWorkout()
            
            default:
                break
        }
        
        updateLabels()
        //updateState()
    }
    
    private func saveWorkout() {
        // Create and save a workout sample
        let configuration = workoutSession!.workoutConfiguration
        let isIndoor = (configuration.locationType == .indoor) as NSNumber
        print("locationType: \(configuration)")
        
        let workout = HKWorkout(activityType: configuration.activityType,
                                start: workoutStartDate!,
                                end: workoutEndDate!,
                                workoutEvents: workoutEvents,
                                totalEnergyBurned: totalEnergyBurned,
                                totalDistance: totalDistance,
                                metadata: [HKMetadataKeyIndoorWorkout:isIndoor]);
        
        healthStore.save(workout) { success, _ in
            if success {
                self.addSamples(toWorkout: workout)
            }
        }
        
        // Pass the workout to Summary Interface Controller
        //WKInterfaceController.reloadRootControllers(withNames: ["SummaryInterfaceController"], contexts: [workout])
    }
    
    private func addSamples(toWorkout workout: HKWorkout) {
        // Create energy and distance samples
        let totalStepsSample = HKQuantitySample(type: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
                                                quantity: totalStepCount,
                                                start: workoutStartDate!,
                                                end: workoutEndDate!)
        let totalEnergyBurnedSample = HKQuantitySample(type: HKQuantityType.activeEnergyBurned(),
                                                       quantity: totalEnergyBurned,
                                                       start: workoutStartDate!,
                                                       end: workoutEndDate!)
        
        let totalDistanceSample = HKQuantitySample(type: HKQuantityType.distanceWalkingRunning(),
                                                   quantity: totalDistance,
                                                   start: workoutStartDate!,
                                                   end: workoutEndDate!)
        
        // Add samples to workout
        healthStore.add([totalEnergyBurnedSample, totalDistanceSample, totalStepsSample], to: workout) { (success: Bool, error: Error?) in
            if success {
                // Samples have been added
            }
        }
    }

}


//
//  WatchSessionManager.swift
//  SpeedySloth
//
//  Created by Janette Cheng on 11/6/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import Foundation
import WatchConnectivity
import FirebaseDatabase
import FirebaseAnalytics

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedManager = WatchSessionManager()
    var ref: FIRDatabaseReference!
    private override init() {
        FIRApp.configure()
        ref = FIRDatabase.database().reference()
        super.init()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession){
        
    }

    func sessionDidDeactivate(_ session: WCSession){
        
    }

    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        let session = self.session
        if (session?.isPaired)! && (session?.isWatchAppInstalled)! {
            return session
        }
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        let steps = userInfo["stepCount"].unsafelyUnwrapped
        let uid = userInfo["uid"].unsafelyUnwrapped
        let key = ref.child("/users/0/").childByAutoId().key
        let post = ["uid": uid,
                    "stepCount":steps]
        let childUpdates = ["/users/0/" + key: post]
        ref.updateChildValues(childUpdates)
    }
}

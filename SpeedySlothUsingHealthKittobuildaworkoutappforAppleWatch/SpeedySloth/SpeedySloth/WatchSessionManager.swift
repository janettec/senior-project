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
    let stepDataFile = "stepData.txt"
    let heartDataFile = "heartData.txt"
    let stepType = 0
    let heartType = 1
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
    
    func clearDocumentsFolder() {
        let fileManager = FileManager.default
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

        if let directoryContents = try? fileManager.contentsOfDirectory(atPath: dirPath) {
            for path in directoryContents {
                let fullPath = (dirPath as NSString).appendingPathComponent(path)
                _ = try? fileManager.removeItem(atPath: fullPath)
            }
        }
    }
    
    func writeToFile( data: String, type: Int, timestamp: String){
        // get the documents folder url
        do {
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            // create the destination url for the text file to be saved
            let filename = type == stepType ? stepDataFile : heartDataFile
            let fileDestinationUrl = documentDirectoryURL.appendingPathComponent(filename)
            
            let text = "\(data),\(timestamp)\n"
            do {
                let fileHandle = try FileHandle(forWritingTo: fileDestinationUrl)
                
                do {
                    //Append to file
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(text.data(using: String.Encoding.utf8)!)
                }
                // writing to disk
                //try text.write(to: fileDestinationUrl, atomically: false, encoding: .utf8)
                
                // saving was successful. any code posterior code goes here
                // reading from disk
//                do {
//                    let mytext = try String(contentsOf: fileDestinationUrl)
//                    print(mytext)   // "some text\n"
//                } catch let error as NSError {
//                    print("error loading contentsOf url \(fileDestinationUrl)")
//                    print(error.localizedDescription)
//                }
            } catch let error as NSError {
                print("error writing to url \(fileDestinationUrl)")
                print(error.localizedDescription)
            }

        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("DATA TRANSFERED TO PHONE")
        guard let type = userInfo["type"] as? NSInteger else {return}
        guard let date = userInfo["date"] as? NSString else {return}
        if (type == stepType) {
            guard let steps = userInfo["stepCount"] as? NSString else {return}
            writeToFile(data: steps as String, type: type as Int, timestamp: date as String)
        } else if (type == heartType) {
            guard let heartRate = userInfo["heartRate"] as? NSString else {return}
            writeToFile(data: heartRate as String, type: type as Int, timestamp: date as String)
        }
        //let uid = userInfo["uid"].unsafelyUnwrapped as AnyObject
        
//        let key = ref.child("/users/0/").childByAutoId().key
//        let post = ["uid": uid,
//                    "stepCount":steps]
//        let childUpdates = ["/users/0/" + key: post]
//        ref.updateChildValues(childUpdates)
    }
}

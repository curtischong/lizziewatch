//
//  WatchNetworkManager.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation
import WatchConnectivity

@available(iOS 11.0, *)
class WatchNetworkManager: NSObject, WCSessionDelegate{
    var mainDelegate : mainProtocol?
    let settingsManager = SettingsManager()
    let dataManager = DataManager()
    let appContextFormatter = DateFormatter()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
    var session: WCSession?
    
    
    override init(){
        super.init()
        appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func processApplicationContext() {
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async(){
            NSLog("received application context!")
            self.processApplicationContext()
        }
    }
    
    
    // this recieves a dictionary of objects from the watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async(){
            // in the future I might want to cast each event into a specific struct
            
            let eventType = userInfo["event"] as! String
            
            if(eventType == "updateLastSync"){
                self.mainDelegate?.updateLastSync(userInfo : userInfo)
            }else if(eventType == "dataStoreMarkEvents"){
                self.mainDelegate?.updateLastSync(userInfo : userInfo)
                self.dataStoreMarkEvents(userInfo: userInfo)
            }else{
                NSLog("Invalid watchContext event received: \(eventType)")
            }
        }
    }
    
    func syncWatchData(){
        if let validSession = session {
            let iPhoneAppContext = ["event" : "syncData", "TimeOfTransfer" : appContextFormatter.string(from: Date())]
            
            do {
                try validSession.updateApplicationContext(iPhoneAppContext)
                NSLog("Told watch to sync data")
                //syncToPhoneStateLabel.text = "told watch sync"
            } catch let error{
                
                //TODO: update a ui element when this happens
                NSLog("Couldn't tell watch to sync with error: \(error)")
            }
        }
    }
    
    
    func dataStoreMarkEvents(userInfo : [String : Any]){
        let endTimeOfQuery = userInfo["endTimeOfQuery"] as! Date
        
        let numItems = userInfo["numItems"] as! Int
        NSLog("Number of items received: \(numItems)")
        
        self.storeMarkEventPhone(markTimes : userInfo["markTimes"] as! [Date], endTimeOfQuery : endTimeOfQuery)
    }
    
    
    // Stores the received data into the phone's coredata, updates the UI (MarkEvent Table View), and notifies the watch it's done syncing
    private func storeMarkEventPhone(markTimes : [Date], endTimeOfQuery : Date){
        var markEventObjs : [MarkEventObj] = []
        for markTime in markTimes{
            markEventObjs.append(MarkEventObj(markTime: markTime))
        }
        if(dataManager.insertMarkEvents(markEvents : markEventObjs)){
            
            settingsManager.dateLastSyncedWithWatch = endTimeOfQuery
            settingsManager.saveSettings()
            
            // TODO: note: the concerns raised above applies to here too
            let dataStorePackage = ["event" : "finishedSyncing",
                                    "syncDataType": "dataStoreMarkEvents",
                                    "selectBeforeTime": endTimeOfQuery] as [String : Any]
            
            session!.transferUserInfo(dataStorePackage)
            self.mainDelegate?.updateMarkEvent()
        }
    }
}

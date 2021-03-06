//
//  InterfaceController.swift
//  Heart Control WatchKit Extension
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import WatchKit
import WatchConnectivity
import CoreData

@available(watchOSApplicationExtension 4.0, *)
class InterfaceController: WKInterfaceController , WCSessionDelegate{

    // MARK: - Outlets

    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var controlButton: WKInterfaceButton!
    @IBOutlet var markEventButton: WKInterfaceButton!
    

    @IBOutlet var markEventCntWatch: WKInterfaceLabel!
    @IBOutlet var syncingStateLabel: WKInterfaceLabel!
    @IBOutlet var dateOfSync: WKInterfaceLabel!
    // MARK: - Properties

    private let workoutManager = WorkoutManager()
    private var dataStoreUrl: URL!
    private var syncingStateBool = false

    var session = WCSession.default
    let context = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext
    
    // VERY IMPORTANT I AM USING THIS FORMATTER BECAUSE APPLICATION CONTEXTS DON'T GET SENT IF THE SAME DATA IS SENT TWICE
    // BY PUTTING THE CURRENT TIME IN MY DATA I ENSURE THAT NEW CALLS ARE ATTEMPTED
    let displayDateFormatter = DateFormatter()

    
    weak var delegate: InterfaceController?

    // MARK: - Lifecycle

    //I think this gets called twice. might want to look into this
    override func willActivate() {
        super.willActivate()

        // Configure workout manager.
        workoutManager.delegate = self
    
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        self.updateMarkEventCnt()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        session.delegate = self
        session.activate()
    }
    //TODO: change the color of the Sync state for each diff state
    

    // MARK: - Actions

    //TODO: rename this method
    @IBAction func startWorkoutButton() {
        switch workoutManager.state {
        case .started:
            // Stop current workout.
            workoutManager.stop()
            break
        case .stopped:
            // Start new workout.
            workoutManager.start()
            break
        }
    }
    @IBAction func toggleShowHRButton(_ value: Bool) {
        workoutManager.showUpdates(shouldShowHR : value)
    }
    
    // DataCore
    
    // Connectivity
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if(activationState == .activated){
            // Update application context here
            NSLog("Currently syncing data to app bc the session is connected")
            // If you have a background transfer that exists bc you messed up
            //DispatchQueue.main.async{
                let transfers = session.outstandingUserInfoTransfers
                if(transfers.count > 0){
                    for trans in transfers{
                        trans.cancel()
                        NSLog("removed transfer: \(trans.userInfo["event"] as! String)")
                    }
                    NSLog("Sorry, app open sync skipped")
                }else{
                    self.sendDataStore()
                }
        }else{
            NSLog("ERROR the activation state is not activated")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async(){
            NSLog("processing app context")
            self.processApplicationContext()
        }
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if(error == nil){
            DispatchQueue.main.async(){
                let transfers = session.outstandingUserInfoTransfers
                if transfers.count > 0 {  //--> will in most cases now be 0
                    var stillTransferring = false
                    for trans in transfers {
                        NSLog("State of transfer: \(trans.isTransferring) for \(trans.userInfo["event"] as! String)")
                        
                        if(!trans.isTransferring && trans.userInfo["event"] as! String != "updateLastSync"){
                            let eventName = trans.userInfo["event"] as! String
                            let selectBeforeTime = trans.userInfo["endTimeOfQuery"] as! NSDate
                            NSLog("Deleting data before time: \(selectBeforeTime)")
                            if(eventName == "dataStoreMarkEvents"){
                                self.dropAllMarkEventRows(selectBeforeTime : selectBeforeTime)
                            }else{
                                NSLog("Can't remove rows of unknown event: \(eventName)")
                            }
                        }else{
                            NSLog("Transfer is still in process")
                            stillTransferring = true
                        }
                    }
                    if(stillTransferring){

                    }else{
                        self.setSyncingState(newSyncState : false)
                    }
                }
            }
        }else {
            NSLog("transfer failed with error \(String(describing: error))")
        }
    }
    
    private func dropAllMarkEventRows(selectBeforeTime : NSDate){
        NSLog("told to drop markevent rows")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
        fetchRequest.predicate = NSPredicate(format: "timeOfMark < %@", selectBeforeTime)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try context.execute(deleteRequest)
            try context.save()
            NSLog("Deleted MarkEventWatch rows")
            updateMarkEventCnt()
        }catch let error{
            NSLog("Couldn't Delete MarkEventWatch rows before this date: \(selectBeforeTime) with error: \(error)")
        }
    }
    
    func processApplicationContext() {
            //TODO: FIX THE SESSION IMPLIMENTATION THIS IS HORRIBLE BC IT IS OPTIONAL
            let iPhoneContext = session.receivedApplicationContext as? [String : String]
            if(iPhoneContext != nil){
                if (iPhoneContext!["event"] == "syncData") {
                    NSLog("Received messsage to sync Data")
                    sendDataStore()
                } else {
                    NSLog("Invalid iPhoneContext event received: \(String(describing: iPhoneContext!["event"]))")
                }
            }
    }
    
    private func sendDataStore(){
        if(!syncingStateBool){
            if(session.outstandingUserInfoTransfers.count == 0){
                setSyncingState(newSyncState : true)
                let selectBeforeTime = Date() as NSDate
                NSLog("Syncing data before time: \(selectBeforeTime)")
                dateOfSync.setText(displayDateFormatter.string(from: selectBeforeTime as Date))
                let request2 = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
                request2.predicate = NSPredicate(format: "timeOfMark < %@", selectBeforeTime)
                
                var bothEmpty = true

                // Now send the MarkEvents
                do{
                    let result2 = try context.fetch(request2)
                    let numItems = result2.count
                    if(numItems > 0 ){
                        bothEmpty = false
                        var markTimes = Array<Date>()
                        for sample in result2 as! [NSManagedObject] {
                            markTimes.append(sample.value(forKey: "timeOfMark") as! Date)
                        }


                        let dataStorePackage2 = ["event" : "dataStoreMarkEvents",
                                                 "markTimes": markTimes,
                                                 "endTimeOfQuery" : selectBeforeTime,
                                                 "numItems" : result2.count] as [String : Any]
                        NSLog("Syncing \(result2.count) items")
                        session.transferUserInfo(dataStorePackage2)
                    }else{
                        NSLog("Turns out there are no MarkEventWatch rows")
                    }
                } catch let error{
                    NSLog("Couldn't fetch MarkEventWatch with error: \(error)")
                }
                if(bothEmpty){
                    let newTime = displayDateFormatter.string(from: selectBeforeTime as Date)
                    let dataToSend = ["event" : "updateLastSync", "selectBeforeTime" : newTime] as [String : Any]
                    
                    session.transferUserInfo(dataToSend)
                    setSyncingState(newSyncState : false)
                    NSLog("Updated phone's last synced time to: \(newTime)")
                }
            }else{
                NSLog("Sorry, already syncing. can't sync")
                for trans in session.outstandingUserInfoTransfers{
                    NSLog("State of transfer: \(trans.isTransferring) for \(trans.userInfo["event"] as! String)")
                }
                
            }
        }else{
            NSLog("Already Syncing")
        }
    }
    
    // Sometimes the transfer delegate callback fails so the phone will send this userinfo to delete the transferred rows
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async(){
            let transfers = session.outstandingUserInfoTransfers
            let eventType = userInfo["event"] as! String
            
            if(eventType == "finishedSyncing"){
                NSLog("received sync callback from phone to remove \( userInfo["syncDataType"] as! String)")
                let syncDataType = userInfo["syncDataType"] as! String
                
                // remove that transfer (bc sometimes it might still be on)
                for trans in transfers{
                    NSLog("current event: \(trans.userInfo["event"] as! String) and \(syncDataType)")
                    if(trans.userInfo["event"] as! String == syncDataType){
                        if(syncDataType == "dataStoreBioSamples"){
                            trans.cancel()
                        }else if(syncDataType == "dataStoreMarkEvents"){
                            trans.cancel()
                        }else{
                            NSLog("Can't find eventType to cancel: \(eventType)")
                        }
                    }
                }
                
                // sometimes the transfers randomly dissapear. This is why I'm not removing them in the transfer loop
                if(syncDataType == "dataStoreMarkEvents"){
                    self.dropAllMarkEventRows(selectBeforeTime : userInfo["selectBeforeTime"] as! NSDate)
                }
                
                var stillTransfering = false
                for trans in transfers{
                    NSLog("State of transfer: \(trans.isTransferring) for \(trans.userInfo["event"] as! String)")
                    if(trans.isTransferring){
                        stillTransfering = true
                    }
                }
                if(!stillTransfering){
                    self.setSyncingState(newSyncState : false)
                }
            }
        }
    }
    
    private func updateMarkEventCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
        do{
            let result = try context.fetch(request)
            markEventCntWatch.setText(String(result.count))
            if(result.count != 0){
                syncingStateLabel.setText("Not Synced")
            }
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    
    private func setSyncingState(newSyncState : Bool){
        syncingStateBool = newSyncState
        if(syncingStateBool){
            syncingStateLabel.setText("Syncing")
        }else{
            syncingStateLabel.setText("Synced")
        }
    }
    
    
    // Stores a mark event to the datastore
    @IBAction func markEventButtonPress() {
        let entity = NSEntityDescription.entity(forEntityName: "MarkEventWatch", in: context)
        let curMark = NSManagedObject(entity: entity!, insertInto: context)
        curMark.setValue(Date(), forKey: "timeOfMark")
        WKInterfaceDevice.current().play(.success)
        do {
            try context.save()
            self.updateMarkEventCnt()
            NSLog("Successfully saved the current MarkEvent")
        } catch let error{
            NSLog("Couldn't save: the current MarkEvent with  error: \(error)")
        }
    }
    
}

// MARK: - Workout Manager Delegate

@available(watchOSApplicationExtension 4.0, *)
extension InterfaceController: WorkoutManagerDelegate {
    
    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState) {
        // Update title of control button.
        controlButton.setTitle(newState.actionText())
    }

    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: Double) {
        // Update heart rate label.
        heartRateLabel.setText(String(format: "%.0f", newHeartRate))
    }

}

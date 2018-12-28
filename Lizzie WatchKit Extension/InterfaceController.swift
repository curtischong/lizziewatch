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
    
    @IBOutlet var bioSampleCntWatch: WKInterfaceLabel!
    @IBOutlet var markEventCntWatch: WKInterfaceLabel!
    @IBOutlet var syncingStateLabel: WKInterfaceLabel!
    // MARK: - Properties

    private let workoutManager = WorkoutManager()
    private var dataStoreUrl: URL!
    private var syncingStateBool = false

    var session = WCSession.default
    let context = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext
    
    // VERY IMPORTANT I AM USING THIS FORMATTER BECAUSE APPLICATION CONTEXTS DON'T GET SENT IF THE SAME DATA IS SENT TWICE
    // BY PUTTING THE CURRENT TIME IN MY DATA I ENSURE THAT NEW CALLS ARE ATTEMPTED
    let formatter = DateFormatter()

    
    weak var delegate: InterfaceController?

    // MARK: - Lifecycle

    //I think this gets called twice. might want to look into this
    override func willActivate() {
        super.willActivate()

        // Configure workout manager.
        workoutManager.delegate = self
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.updateBioSampleCnt()
        self.updateMarkEventCnt()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        session.delegate = self
        session.activate()
    }
    

    // MARK: - Actions

    //TODO: rename this method
    @IBAction func didTapButton() {
        print("tapped button")
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

    // DataCore
    
    // Connectivity
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            // Update application context here
            NSLog("Currently syncing data to app bc the session is connected")
            // If you have a background transfer that exists bc you messed up
            //DispatchQueue.main.async{
                let transfers = WCSession.default.outstandingUserInfoTransfers
                if(transfers.count > 0){
                    for trans in transfers{
                        trans.cancel()
                        NSLog("removed transfer: \(trans.userInfo["event"] as! String)")
                    }
                    NSLog("Sorry, app open sync skipped")
                }else{
                    self.sendDataStore()
                }
           // }
            
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
        if error == nil {
            DispatchQueue.main.async(){
                let transfers = WCSession.default.outstandingUserInfoTransfers
                if transfers.count > 0 {  //--> will in most cases now be 0
                    var stillTransferring = false
                    for trans in transfers {
                        NSLog("State of transfer: \(trans.isTransferring) for \(trans.userInfo["event"] as! String)")
                        
                        if(!trans.isTransferring){
                            let eventName = trans.userInfo["event"] as! String
                            let selectBeforeTime = trans.userInfo["endTimeOfQuery"] as! NSDate
                            NSLog("Deleting data before time: \(selectBeforeTime)")
                            if(eventName == "dataStoreBioSamples"){
                                self.dropAllBioSampleRows(selectBeforeTime : selectBeforeTime)
                                //self.dropAllRowsOfTypeBefore(dataType: "BioSampleWatch",
                                //                             selectBeforeTime : selectBeforeTime,
                                //                             dateSelector : "endTime")
                            }else if(eventName == "dataStoreMarkEvents"){
                                self.dropAllMarkEventRows(selectBeforeTime : selectBeforeTime)
                                //self.dropAllRowsOfTypeBefore(dataType: "MarkEventWatch",
                                //                             selectBeforeTime : selectBeforeTime,
                                //                             dateSelector : "timeOfMark")
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
    
    private func dropAllBioSampleRows(selectBeforeTime : NSDate){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
        fetchRequest.predicate = NSPredicate(format: "endTime < %@", selectBeforeTime)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try context.execute(deleteRequest)
            try context.save()
            NSLog("Deleted BioSampleWatch rows")
            updateBioSampleCnt()
        }catch let error{
            NSLog("Couldn't Delete BioSampleWatch rows before this date: \(selectBeforeTime) with error: \(error)")
        }
    }
    
    private func dropAllMarkEventRows(selectBeforeTime : NSDate){
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
    
    private func dropAllRowsOfTypeBefore(dataType : String, selectBeforeTime : NSDate, dateSelector : String){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: dataType)
        NSLog("Using predicate: %@ < %@", dateSelector,selectBeforeTime as NSDate)
        fetchRequest.predicate = NSPredicate(format: "%@ < %@", dateSelector, selectBeforeTime)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do{
            try context.execute(deleteRequest)
            try context.save()
            NSLog("Deleted \(dataType) rows")
            //TODO: do the right update
            //updateBioSampleCnt()
        }catch let error{
            NSLog("Couldn't Delete \(dataType) rows before this date: \(selectBeforeTime) with \(error)")
        }
    }
    
    func processApplicationContext() {
        if(!syncingStateBool){
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
        }else{
            NSLog("Already Syncing")
        }
    }
    
    private func sendDataStore(){
        // I'm pretty sure the session on the watch side is ALWAYS on. bc it assumes the phone is on
        //if let validSession = session {
        if(WCSession.default.outstandingUserInfoTransfers.count == 0){
            setSyncingState(newSyncState : true)
            let selectBeforeTime = Date() as NSDate
            NSLog("Syncing data before time: \(selectBeforeTime)")
            let request1 = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
            request1.predicate = NSPredicate(format: "endTime < %@", selectBeforeTime)
            let request2 = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
            request2.predicate = NSPredicate(format: "timeOfMark < %@", selectBeforeTime)
            
            var bothEmpty = true
            do{
                let result1 = try context.fetch(request1)
                let numItems = result1.count
                if(numItems > 0 ){
                    bothEmpty = false
                    var samplesNames = Array<String>()
                    var samplesStartTime = Array<Date>()
                    var samplesEndTime = Array<Date>()
                    var samplesMeasurement = Array<Double>()

                
                    for sample in result1 as! [NSManagedObject] {
                        // This casting is weird / might use battery. find a way to change it
                        samplesNames.append(sample.value(forKey: "dataPointName") as! String)
                        samplesStartTime.append(sample.value(forKey: "startTime") as! Date)
                        samplesEndTime.append(sample.value(forKey: "endTime") as! Date)
                        samplesMeasurement.append(sample.value(forKey: "measurement") as! Double)
                    }
                    
                    let dataStorePackage1 = ["event" : "dataStoreBioSamples",
                                             "samplesNames": samplesNames,
                                             "samplesStartTime": samplesStartTime,
                                             "samplesEndTime": samplesEndTime,
                                             "samplesMeasurement": samplesMeasurement,
                                             "endTimeOfQuery" : selectBeforeTime,
                                             "numItems" : numItems] as [String : Any]
                    
                    NSLog("Syncing \(result1.count) items")
                    session.transferUserInfo(dataStorePackage1)
                }else{
                    NSLog("Turns out there are no BioSampleWatch rows")
                }
            } catch let error{
                NSLog("Couldn't fetch BioSampleWatch with error: \(error)")
            }
            // Now send the MarkEvents
            do{
                let result2 = try context.fetch(request2)
                let numItems = result2.count
                if(numItems > 0 ){
                    bothEmpty = false
                    var timeOfMarks = Array<Date>()
                    for sample in result2 as! [NSManagedObject] {
                        timeOfMarks.append(sample.value(forKey: "timeOfMark") as! Date)
                    }


                    let dataStorePackage2 = ["event" : "dataStoreMarkEvents",
                                             "timeOfMarks": timeOfMarks,
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
                setSyncingState(newSyncState : false)
            }
        }else{
            NSLog("Sorry, already syncing. can't sync")
            for trans in WCSession.default.outstandingUserInfoTransfers{
                NSLog("State of transfer: \(trans.isTransferring) for \(trans.userInfo["event"] as! String)")
            }
            
        }
    }
    
    private func updateBioSampleCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
        do{
            let result = try context.fetch(request)
            bioSampleCntWatch.setText(String(result.count))
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    private func updateMarkEventCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
        do{
            let result = try context.fetch(request)
            markEventCntWatch.setText(String(result.count))
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    
    private func setSyncingState(newSyncState : Bool){
        syncingStateBool = newSyncState
        if(syncingStateBool){
            syncingStateLabel.setText("Syncing")
        }else{
            syncingStateLabel.setText("Not Syncing")
        }
    }
    
    
    // Stores a mark event to the datastore
    @IBAction func markEventButtonPress() {
        let entity = NSEntityDescription.entity(forEntityName: "MarkEventWatch", in: context)
        let curMark = NSManagedObject(entity: entity!, insertInto: context)
        curMark.setValue(Date(), forKey: "timeOfMark")
        
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
    func notifyUpdateBioSampleCnt() {
        updateBioSampleCnt()
    }
    
    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState) {
        // Update title of control button.
        controlButton.setTitle(newState.actionText())
    }

    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: Double) {
        // Update heart rate label.
        heartRateLabel.setText(String(format: "%.0f", newHeartRate))
    }

}

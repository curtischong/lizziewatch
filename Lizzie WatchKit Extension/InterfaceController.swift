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
    
    @IBOutlet var watchBioSampleCnt: WKInterfaceLabel!
    @IBOutlet var watchMarkEventCnt: WKInterfaceLabel!
    // MARK: - Properties

    private let workoutManager = WorkoutManager()
    private let dataStore = DataStore()
    private var dataStoreUrl: URL!

    var session = WCSession.default
    let context = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext

    
    weak var delegate: InterfaceController?

    // MARK: - Lifecycle

    //I think this gets called twice. might want to look into this
    override func willActivate() {
        super.willActivate()

        // Configure workout manager.
        workoutManager.delegate = self
        
        // testing the watch's DataCore
        
        /*let curSample = HealthKitDataPoint(
            dataPointName: "random name",
            startTime: Date(),
            endTime: Date() + 5,
            measurement: 5.0
        )*/
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
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func processApplicationContext() {
        //TODO: FIX THE SESSION IMPLIMENTATION THIS IS HORRIBLE BC IT IS OPTIONAL
        let iPhoneContext = session.receivedApplicationContext as? [String : String]
        if(iPhoneContext != nil){
            
            
            if (iPhoneContext!["event"] == "syncData") {
                NSLog("Syncing Data")
                sendDataStore()
            } else {
                NSLog("Invalid iPhoneContext event received: \(String(describing: iPhoneContext!["event"]))")
            }
        }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async() {
            self.processApplicationContext()
        }
    }
    

    
    
    private func sendDataStore(){
        //if let validSession = session {
            
            let request1 = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
            let request2 = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
            do{
                let result1 = try context.fetch(request1)
                
                var samples1 = Array<HealthKitDataPoint>()

            
                for sample in result1 as! [NSManagedObject] {
                    let curSample = HealthKitDataPoint(
                        dataPointName: sample.value(forKey: "dataPointName") as! String,
                        startTime: sample.value(forKey: "startTime") as! Date,
                        endTime: sample.value(forKey: "endTime") as! Date,
                        measurement: sample.value(forKey: "measurement") as! Double
                    )
                    samples1.append(curSample)
                }
                
                let dataStorePackage1 = ["event" : "dataStoreBioSamples", "samples": samples1, "numItems" : samples1.count] as [String : Any]
                
                NSLog("Told watch to sync data")
                let transfer1 = session.transferUserInfo(dataStorePackage1)
                
                
                
                // Now send the MarkEvents
                
                
                /*
                
                
                let result2 = try context.fetch(request2)
                
                var samples2 = Array<Date>()
                for sample in result2 as! [NSManagedObject] {
                    let curSample = HealthKitDataPoint(
                        dataPointName: sample.value(forKey: "dataPointName") as! String,
                        startTime: sample.value(forKey: "startTime") as! Date,
                        endTime: sample.value(forKey: "endTime") as! Date,
                        measurement: sample.value(forKey: "measurement") as! Double
                    )
                    samples1.append(curSample)
                }
                

                let dataStorePackage2 = ["event" : "dataStoreMarkEvents", "samples": samples2, "numItems" : samples2.count] as [String : Any]
                let transfer2 = session.transferUserInfo(dataStorePackage2)
                 */
            } catch let error{
                NSLog("Couldn't access CoreData: \(error)")
            }
            
        //}
    }
    
    private func updateBioSampleCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
        do{
            let result = try context.fetch(request)
            watchBioSampleCnt.setText(String(result.count))
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    private func updateMarkEventCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventWatch")
        do{
            let result = try context.fetch(request)
            watchMarkEventCnt.setText(String(result.count))
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
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
            NSLog("Successfully saved the current EventMark")
        } catch let error{
            NSLog("Couldn't save: the current EventMark with  error: \(error)")
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

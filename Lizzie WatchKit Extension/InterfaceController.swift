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
class InterfaceController: WKInterfaceController, WCSessionDelegate {

    // MARK: - Outlets

    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var controlButton: WKInterfaceButton!
    @IBOutlet var aLabel: WKInterfaceLabel!
    @IBOutlet var fileSender: WKInterfaceButton!
    @IBOutlet var fileReader: WKInterfaceButton!
    
    // MARK: - Properties

    private let workoutManager = WorkoutManager()
    private let dataStore = DataStore()
    private var dataStoreUrl: URL!
    let session = WCSession.default
    let context = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext

    
    

    // MARK: - Lifecycle

    override func willActivate() {
        super.willActivate()

        // Configure workout manager.
        workoutManager.delegate = self
        
        // testing the watch's DataCore
        
        let curSample = HealthKitDataPoint(
            dataPointName: "random name",
            startTime: Date(),
            endTime: Date() + 5,
            measurement: 5.0
        )
        self.storeBioSampleWatch(bioSample : curSample)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        processApplicationContext()
        
        session.delegate = self
        session.activate()
    }

    // MARK: - Actions

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
    
    
    
    
    private func storeBioSampleWatch(bioSample : HealthKitDataPoint){
        let entity = NSEntityDescription.entity(forEntityName: "BioSample2", in: context)
        let healthSample = NSManagedObject(entity: entity!, insertInto: context)
        healthSample.setValue(bioSample.dataPointName, forKey: "dataPointName")
        healthSample.setValue(bioSample.startTime, forKey: "startTime")
        healthSample.setValue(bioSample.endTime, forKey: "endTime")
        healthSample.setValue(bioSample.measurement, forKey: "measurement")
        
        do {
            try context.save()
        } catch let error{
            NSLog("Couldn't save: \(bioSample.printVals()) with  error: \(error)")
        }
    }
    
    
    
    
    
    
    // TODO: add a test for this function
    // Saves the bioSamples to the watch's DataCore
    /*private func storeBioSampleWatch(bioSample : HealthKitDataPoint){
        //let entity = NSEntityDescription.entityForName("OneItemCD", inManagedObjectContext: self.managedObjectContext)

        guard let appDelegate = WKExtension.shared().delegate as? ExtensionDelegate else { return }
        let context = appDelegate.persistentContainer!.viewContext

        
        let entity = NSEntityDescription.entity(forEntityName: "BioSample", in: context)
        let healthSample = NSManagedObject(entity: entity!, insertInto: context)*/
        /*healthSample.setValue(bioSample.dataPointName, forKey: "dataPointName")
        healthSample.setValue(bioSample.startTime, forKey: "startTime")
        healthSample.setValue(bioSample.endTime, forKey: "endTime")
        healthSample.setValue(bioSample.measurement, forKey: "measurement")
        
        do {
            try context.save()
            NSLog("Saved sample to CoreData!")
        } catch let error{
            NSLog("Couldn't save: \(bioSample.printVals()) with error: \(error)")
        }*/
    //}
    
    // Connectivity
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func processApplicationContext() {
        let iPhoneContext = session.receivedApplicationContext as? [String : Bool]
        if(iPhoneContext != nil){
            
            
            if iPhoneContext!["switchStatus"] == true {
                aLabel.setText("Switch On")
            } else {
                aLabel.setText("Switch Off")
            }
        }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async() {
            self.processApplicationContext()
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

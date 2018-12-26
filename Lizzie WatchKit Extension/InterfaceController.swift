//
//  InterfaceController.swift
//  Heart Control WatchKit Extension
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import WatchKit
import WatchConnectivity

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

    // MARK: - Lifecycle

    override func willActivate() {
        super.willActivate()

        // Configure workout manager.
        workoutManager.delegate = self
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
    @IBAction func sendTheFile() {
        NSLog("Saving to File")
        dataStoreUrl = dataStore.saveToFile()
        NSLog("File saved!")
    }
    @IBAction func readFile() {
        NSLog("Reading File")
        dataStore.readFromFile(dataStoreUrl: dataStoreUrl)
        NSLog("File Read!")
    }
    
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

extension InterfaceController: WorkoutManagerDelegate {

    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState) {
        // Update title of control button.
        controlButton.setTitle(newState.actionText())
    }

    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: HeartRate) {
        // Update heart rate label.
        heartRateLabel.setText(String(format: "%.0f", newHeartRate.bpm))
    }

}

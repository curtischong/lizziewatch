//
//  Authenticate.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-01-03.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation
import HealthKit

let healthStore = HKHealthStore()


func authenticateForHealthstoreData() -> Bool{
        // Create health store.
    if #available(iOS 11.0, *) {
        NSLog("can read all healthStore Datapoints!")
        // Check if there is health data available.
        if (!HKHealthStore.isHealthDataAvailable()) {
            print("No health data is available.")
            return false
        }
        
        // Create quantity type for heart rate.
        guard let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Unable to create quantity type for heart rate.")
            return false
        }
        
        
        // Create quantity type for heart rate.
    
            guard let vo2MaxQuantityType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
                print("Unable to create quantity type for vo2Max.")
                return false
            }
    
        
        guard let distanceWalkingRunningQuantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            print("Unable to create quantity type for distanceWalkingRunning.")
            return false
        }
        
        let allTypes = Set([heartRateQuantityType,
                            vo2MaxQuantityType,
                            distanceWalkingRunningQuantityType,
                            HKObjectType.workoutType()])
        
        
        
        var authSuccess = false
        
        // Request authorization to read heart rate data.
        healthStore.requestAuthorization(toShare: nil, read: allTypes) { (success, error) in
            // If there is an error, do nothing.
            guard error == nil else {
                print(error ?? "failed during healthkit auth")
                authSuccess = false
                return
            }
            NSLog("HaveAuthentication: \(success)")
            // Delegate success.
            authSuccess = true
        }
        return authSuccess
    } else {
        NSLog("can't read all healthStore Datapoints. App won't read any healthstore Datapoints")
        // Fallback on earlier versions
        return false
    }
}


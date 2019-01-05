//
//  Authenticate.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-01-03.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation
import HealthKit

/*
func authenticateForHealthstoreData(){
    var shareTypes = Set<HKSampleType>()
    shareTypes.insert(HKSampleType.workoutType())
    
    var readTypes = Set<HKObjectType>()
    readTypes.insert(HKObjectType.workoutType())//,
                     //HKQuantityType.quantityType(forIdentifier: .respiratoryRate))
    
    healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) -> Void in
        if success {
            print("success")
        } else {
            print("failure")
        }
        
        if let error = error { print(error) }
    }
}*/

let healthStore = HKHealthStore()


func authenticateForHealthstoreData() {
        // Create health store.
    if #available(iOS 11.0, *) {
        NSLog("can read vo2max!")
        // Check if there is health data available.
        if (!HKHealthStore.isHealthDataAvailable()) {
            print("No health data is available.")
            return
        }
        
        // Create quantity type for heart rate.
        guard let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Unable to create quantity type for heart rate.")
            return
        }
        
        
        // Create quantity type for heart rate.
    
            guard let vo2MaxQuantityType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
                print("Unable to create quantity type for vo2Max.")
                return
            }
    
        
        guard let distanceWalkingRunningQuantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            print("Unable to create quantity type for distanceWalkingRunning.")
            return
        }
        
        let allTypes = Set([heartRateQuantityType,
                            vo2MaxQuantityType,
                            distanceWalkingRunningQuantityType,
                            HKObjectType.workoutType()])
        
        
        // Request authorization to read heart rate data.
        healthStore.requestAuthorization(toShare: nil, read: allTypes) { (success, error) -> Void in
            // If there is an error, do nothing.
            guard error == nil else {
                print(error ?? "failed during healthkit auth")
                return
            }
            NSLog("HaveAuthentication: \(success)")
            // Delegate success.
        }
    } else {
        NSLog("can't read vo2max :(")
        // Fallback on earlier versions
    }
}


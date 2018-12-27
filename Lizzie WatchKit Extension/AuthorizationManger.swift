//
//  HKAuthorizationManger.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 07/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import HealthKit

class AuthorizationManager {

    @available(watchOSApplicationExtension 4.0, *)
    static func requestAuthorization(completionHandler: @escaping ((_ success: Bool) -> Void)) {
        // Create health store.
        let healthStore = HKHealthStore()

        // Check if there is health data available.
        if (!HKHealthStore.isHealthDataAvailable()) {
            print("No health data is available.")
            completionHandler(false)
            return
        }

        // Create quantity type for heart rate.
        guard let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("Unable to create quantity type for heart rate.")
            completionHandler(false)
            return
        }
        
        // Create quantity type for heart rate.
        guard let vo2MaxQuantityType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            print("Unable to create quantity type for vo2Max.")
            completionHandler(false)
            return
        }

        let allTypes = Set([heartRateQuantityType,
                            vo2MaxQuantityType])
        
        // Request authorization to read heart rate data.
        healthStore.requestAuthorization(toShare: nil, read: allTypes) { (success, error) -> Void in
            // If there is an error, do nothing.
            guard error == nil else {
                print(error ?? "failed during healthkit auth")
                completionHandler(false)
                return
            }

            // Delegate success.
            completionHandler(success)
        }
    }

}

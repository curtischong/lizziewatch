//
//  Authenticate.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-01-03.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation
import HealthKit

var healthStore = HKHealthStore()
func authenticateForHealthstoreData(){
    var shareTypes = Set<HKSampleType>()
    shareTypes.insert(HKSampleType.workoutType())
    
    var readTypes = Set<HKObjectType>()
    readTypes.insert(HKObjectType.workoutType())
    
    healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) -> Void in
        if success {
            print("success")
        } else {
            print("failure")
        }
        
        if let error = error { print(error) }
    }
}

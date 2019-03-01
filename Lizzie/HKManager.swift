//
//  HKManager.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation
import HealthKit

class HKManager{
    let settingsManager = SettingsManager()
    init(){
        
    }
    
    
    func queryBioSamples(startDate : Date, endDate : Date) -> [HKQuantitySample]{
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date)
        
        var retSamples : [HKQuantitySample] = []
        let query = HKSampleQuery.init(sampleType: HKSampleType.quantityType(forIdentifier: .heartRate)!,
                                       predicate: predicate,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
                                        
                                        if(error != nil){
                                            NSLog("couldn't get healthquery data with error: \(error!)")
                                        }
                                        
                                        guard let samples = results as? [HKQuantitySample] else {
                                            fatalError("Couldn't cast the HKQuantities into an array with error: \(error!)");
                                        }
                                        NSLog("found \(retSamples.count) health samples")
                                        retSamples = samples
        }
        healthStore.execute(query)
        return retSamples
    }
    
    func loadWorkouts(completion: @escaping (([HKWorkout]?, Error?) -> Swift.Void)){
        NSLog("finding workouts")
        
        //1. Get all workouts with the "Other" activity type.
        //let workoutPredicate = HKQuery.predicateForWorkouts(with: .other)
        
        //2. Get all workouts that only came from this app.
        let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
        
        //3. Combine the predicates into a single predicate.
        //let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, sourcePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                              ascending: true)
        
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                  predicate: sourcePredicate,
                                  limit: 10, // limit 0 returns all workout data
        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            DispatchQueue.main.async {
                
                //4. Cast the samples as HKWorkout
                guard let samples = samples as? [HKWorkout],
                    error == nil else {
                        completion(nil, error)
                        return
                }
                
                completion(samples, nil)
            }
        }
        
        HKHealthStore().execute(query)
    }

    
}

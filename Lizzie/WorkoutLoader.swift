//
//  WorkoutLoader.swift
//  Lizzie
//
//  Created by Curtis Chong on 2018-12-31.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//
/*
import HealthKit
class WorkoutLoader(){
    //1. Get all workouts with the "Other" activity type.
    let workoutPredicate = HKQuery.predicateForWorkouts(with: .other)
    
    //2. Get all workouts that only came from this app.
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())
    
    //3. Combine the predicates into a single predicate.
    let compound = NSCompoundPredicate(andPredicateWithSubpredicates:
        [workoutPredicate, sourcePredicate])
    
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                          ascending: true)
    
    let query = HKSampleQuery(
        sampleType: .workoutType(),
        predicate: compound,
        limit: 0,
        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
                guard
                    let samples = samples as? [HKWorkout],
                    error == nil
                    else {
                        completion(nil, error)
                        return
                }
                
                completion(samples, nil)
            }
    }
    
    HKHealthStore().execute(query)
}*/

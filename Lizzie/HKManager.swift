//
//  HKManager.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation
import HealthKit
import CoreData

class HKManager{
    let settingsManager = SettingsManager()
    let healthStore = HKHealthStore()
    init(){
        
    }
    
    
    func queryBioSamples(startDate : Date, endDate : Date, descending : Bool = false) -> [HKQuantitySample]{
        NSLog("\(startDate)")
        NSLog("\(endDate)")
        var sortDescriptors : [NSSortDescriptor]?
        if(descending){
            sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date)
        
        var retSamples : [HKQuantitySample] = []
        let query = HKSampleQuery(sampleType: HKSampleType.quantityType(forIdentifier: .heartRate)!,
                                       predicate: predicate,
                                       limit: Int(HKObjectQueryNoLimit),
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
    
    func handleBioSamples(samples : [HKQuantitySample], startDate : Date, endDate : Date) -> [BioSampleObj]{
        var bioSamples = Array<BioSampleObj>()
        
        for sample in samples{
            var measurementValue = -1.0
            var type = "-1"
            switch sample.quantityType.identifier{
            case "HKQuantityTypeIdentifierHeartRate":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit.beatsPerMinute())
                type = "HR"
            case "HKQuantityTypeIdentifierVO2Max":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit(from: "ml/kg*min"))
                type = "O2"
            default:
                //TODO: find a better way to report this error
                NSLog("Can't find a quantity type for: %@", sample.quantityType.identifier)
            }
            
            let sampleEndTime = sample.endDate
            let sampleStartTime = sample.startDate
            
            if(sampleEndTime > startDate && sampleEndTime < endDate){
                bioSamples.append(BioSampleObj(
                    type: type,
                    startTime : sampleStartTime,
                    endTime : sampleEndTime,
                    measurement : measurementValue))
            }
        }
        if(bioSamples.count == 0){
            NSLog("No bioSamples found")
        }
        return bioSamples
    }
    
    private func castHKUnitToDouble(theSample :HKQuantitySample, theUnit : HKUnit) -> Double{
        if(!theSample.quantity.is(compatibleWith: theUnit)){
            NSLog("measurement value type of %@ isn't compatible with %@" , theSample.quantityType.identifier, theUnit)
            return -1.0
        }else{
            return theSample.quantity.doubleValue(for: theUnit)
        }
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

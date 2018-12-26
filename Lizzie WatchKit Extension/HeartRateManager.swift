//
//  HeartRateManager.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import HealthKit

typealias HKQueryUpdateHandler = ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Swift.Void)

protocol HeartRateManagerDelegate: class {

    func heartRate(didChangeTo newHeartRate: Double)

}

@available(watchOSApplicationExtension 4.0, *)
class HeartRateManager {

    // MARK: - Properties

    private let healthStore = HKHealthStore()

    weak var delegate: HeartRateManagerDelegate?

    private var activeQueries = [HKQuery]()

    // MARK: - Initialization

    init() {
        // Request authorization to read heart rate data.
        AuthorizationManager.requestAuthorization { (success) in
            // TODO: Export error.
            NSLog("Successfully authorized app: %d", success)
        }
        // Fallback on earlier versions
        print("app needs watchos 4+ to run")
    }

    // MARK: - Public API

    func start() {
        // Configure heart rate quantity type.
        buildQuery(HKIdentifier: HKQuantityTypeIdentifier.heartRate)
        buildQuery(HKIdentifier: HKQuantityTypeIdentifier.vo2Max)
    }
    
    func buildQuery(HKIdentifier : HKQuantityTypeIdentifier){
        // queries for a specific HK sample
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKIdentifier) else { return }
        
        // Create query to receive continiuous heart rate samples.
        let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        let updateHandler: HKQueryUpdateHandler = { [weak self] query, samples, deletedObjects, queryAnchor, error in
            if let quantitySamples = samples as? [HKQuantitySample] {
                self?.process(samples: quantitySamples)
            }
        }
        let query = HKAnchoredObjectQuery(type: quantityType,
                                          predicate: queryPredicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        
        // Execute the heart rate query.
        healthStore.execute(query)
        NSLog("Executed the heart rate query")
        
        // Remember all active Queries to stop them later.
        activeQueries.append(query)
        
    }
    
    
    

    func stop() {
        // Stop all active queries.
        activeQueries.forEach { healthStore.stop($0) }
        activeQueries.removeAll()
        NSLog("Removed all queries")
    }

    // MARK: - Process

    private func process(samples: [HKQuantitySample]) {
        // Process every single sample.
        samples.forEach { process(sample: $0) }
    }

    private func castHKUnitToDouble(theSample :HKQuantitySample, theUnit : HKUnit) -> Double{
        /*if(!theSample.quantity.is(compatibleWith: theUnit)){
            NSLog("measurement value type of %@ isn't compatible with %@" , theSample.quantityType.identifier, theUnit)
            return -1.0
        }else{*/
            return theSample.quantity.doubleValue(for: theUnit)
        //}
    }
    
    private func sampleTypeCompatibleWithHKUnit(theQuantityType :HKQuantity, theUnit : HKUnit) -> Bool{
        if (!theQuantityType.is(compatibleWith: theUnit)) {
            return false
        }
        return true
    }
    
    private func process(sample: HKQuantitySample) {
        // If sample is not a heart rate sample, then do nothing.
        
        var measurementValue = -1.0
        switch sample.quantityType.identifier{
            case "heartRate":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit.beatsPerMinute())
            case "vo2Max":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit(from: "ml/kg*min"))
        default:
            NSLog("Can't find a quantity type for: %@", sample.quantityType.identifier)
        
        let curSample = HealthKitDataPoint(
            dataPointName: sample.quantityType.identifier,
            startTime: sample.startDate,
            endTime: sample.endDate,
            measurement: measurementValue
        )
        curSample.printVals()
        

        // Delegate new heart rate.
        //let newHeartRate = HeartRate(timestamp: timestamp, bpm: count)
        delegate?.heartRate(didChangeTo: measurementValue)
    }

}
}

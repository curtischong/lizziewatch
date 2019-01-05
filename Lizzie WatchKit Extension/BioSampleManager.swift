//
//  BioSampleManager.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import HealthKit
import WatchKit
import CoreData

typealias HKQueryUpdateHandler = ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Swift.Void)

protocol BioSampleManagerDelegate: class {
    func updateHeartRate(didChangeTo newHeartRate: Double)
}

@available(watchOSApplicationExtension 4.0, *)
class BioSampleManager {
    
    // MARK: - Properties

    private let healthStore = HKHealthStore()
    var showHeartrate = true

    weak var delegate: BioSampleManagerDelegate?

    private var activeQueries = [HKQuery]()
    let context = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext

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
        NSLog("sent HK queries!")
        buildQuery(HKIdentifier: HKQuantityTypeIdentifier.heartRate)
        buildQuery(HKIdentifier: HKQuantityTypeIdentifier.vo2Max)
    }
    
    // https://stackoverflow.com/questions/46835438/how-to-save-an-array-of-hkquantitysamples-heart-rate-to-a-workout
    
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
        NSLog("Executed the \(quantityType) query")
        
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
        NSLog("received \(samples.count) samples")
        //NSLog("received sample \(samples[0].quantity) and \(samples[0].quantityType)")
        samples.forEach { process(sample: $0) }
    }

    private func castHKUnitToDouble(theSample :HKQuantitySample, theUnit : HKUnit) -> Double{
        return theSample.quantity.doubleValue(for: theUnit)
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
            case "HKQuantityTypeIdentifierHeartRate":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit.beatsPerMinute())
                if(showHeartrate){
                    delegate?.updateHeartRate(didChangeTo: measurementValue)
                }
            case "HKQuantityTypeIdentifierVO2Max":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit(from: "ml/kg*min"))
            default:
                //TODO: find a better way to report this error
                NSLog("Can't find a quantity type for: %@", sample.quantityType.identifier)
        }
    }
}

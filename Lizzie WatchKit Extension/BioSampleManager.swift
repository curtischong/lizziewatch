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
    func notifyUpdateBioSampleCnt()
}

@available(watchOSApplicationExtension 4.0, *)
class BioSampleManager {
    
    // MARK: - Properties

    private let healthStore = HKHealthStore()

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
            case "HKQuantityTypeIdentifierHeartRate":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit.beatsPerMinute())
                delegate?.updateHeartRate(didChangeTo: measurementValue)
            case "HKQuantityTypeIdentifierVO2Max":
                measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit(from: "ml/kg*min"))
            default:
                NSLog("Can't find a quantity type for: %@", sample.quantityType.identifier)
        }
        
        
        let curSample = HealthKitDataPoint(
            dataPointName: sample.quantityType.identifier,
            startTime: sample.startDate,
            endTime: sample.endDate,
            measurement: measurementValue
        )
        //curSample.printVals()
        

        // Delegate new heart rate.
        //let newHeartRate = HeartRate(timestamp: timestamp, bpm: count)
        self.storeBioSampleWatch(bioSample : curSample)
    }
    
    
    
    // TODO: add a test for this function
    // Saves the bioSamples to the watch's DataCore
    // mght want to move this somewhere else
    private func storeBioSampleWatch(bioSample : HealthKitDataPoint){
        let entity = NSEntityDescription.entity(forEntityName: "BioSampleWatch", in: context)
        let healthSample = NSManagedObject(entity: entity!, insertInto: context)
        healthSample.setValue(bioSample.dataPointName, forKey: "dataPointName")
        healthSample.setValue(bioSample.startTime, forKey: "startTime")
        healthSample.setValue(bioSample.endTime, forKey: "endTime")
        healthSample.setValue(bioSample.measurement, forKey: "measurement")
        
        do {
            try context.save()
            delegate?.notifyUpdateBioSampleCnt()
        } catch let error{
            NSLog("Couldn't save: \(bioSample.printVals()) with  error: \(error)")
        }
    }

}

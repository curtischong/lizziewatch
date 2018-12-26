//
//  HealthKitDataPoint.swift
//  Lizzie WatchKit Extension
//
//  Created by Curtis Chong on 2018-12-25.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import Foundation
import HealthKit

struct HealthKitDataPoint {
    var dataPointName: String
    var startTime: Date
    var endTime: Date
    var measurement: Double
    
    var dictionaryRepresentation: [String: Any] {
        return [
            "dataPointName" : self.dataPointName,
            "startTime" : self.startTime,
            "endTime" : self.endTime,
            "measurement" : self.measurement
        ]
    }
    func printVals(){
        NSLog("This is the HealthKitDataPoint object: \(self.dictionaryRepresentation as AnyObject)")
    }
}

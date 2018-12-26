//
//  HealthKitDataPoint.swift
//  Lizzie WatchKit Extension
//
//  Created by Curtis Chong on 2018-12-25.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import Foundation

struct HealthKitDataPoint {
    var dataPointName: String
    var startTime: NSDate
    var endTime: NSDate
    var measurement: Double
}

//
//  BioSampleObj.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

class BioSampleObj{
    var type : String = ""
    var startTime : Date
    var endTime : Date
    var measurement : Double
    
    init(type : String,
        startTime : Date,
        endTime : Date,
        measurement : Double){
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.measurement = measurement
    }
}

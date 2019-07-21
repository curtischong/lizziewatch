	//
//  MarkEventObj.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

//TODO: set startTime to "" if anticipate is false

    
class MarkEventObj{
    var markTime: Date = Date.from(year: 1970, month: 1, day: 1)!
    var name: String = ""
    var anticipate: Bool = true
    var startTime: Date = Date.from(year: 1970, month: 1, day: 1)!
    var eventTime: Date = Date.from(year: 1970, month: 1, day: 1)!
    var endTime: Date = Date.from(year: 1970, month: 1, day: 1)!
    var emotionsFelt: [String : Int] = ["anger": 0,
                                         "contempt": 0,
                                         "disgust": 0,
                                         "fear": 0,
                                         "interest": 0,
                                         "joy": 0,
                                         "sad": 0,
                                         "surprise": 0]
    var selectionRange: Double = 0.2
    var lcrop: Double = 0.0
    var mcrop: Double = 0.5
    var rcrop: Double = 1.0
    var pointsSelected: Bool = false
    var comment : String = ""
    
    init(markTime : Date,
         name: String,
         anticipate : Bool,
         startTime : Date,
         eventTime : Date,
         endTime : Date,
         emotionsFelt : [String : Int],
         selectionRange: Double,
         lcrop: Double,
         mcrop: Double,
         rcrop: Double,
         pointsSelected: Bool,
         comment : String){
        
        self.markTime = markTime
        self.name = name
        self.anticipate = anticipate
        self.startTime = startTime
        self.eventTime = eventTime
        self.endTime = endTime
        self.emotionsFelt = emotionsFelt
        self.selectionRange = selectionRange
        self.lcrop = lcrop
        self.mcrop = mcrop
        self.rcrop = rcrop
        self.pointsSelected = pointsSelected
        self.comment = comment
    }
    
    init(markTime : Date,
         name: String,
         anticipate : Bool,
         startTime : Date,
         eventTime : Date,
         endTime : Date,
         emotionsFelt : [String : Int],
         comment : String){
        
        self.markTime = markTime
        self.name = name
        self.anticipate = anticipate
        self.startTime = startTime
        self.eventTime = eventTime
        self.endTime = endTime
        self.emotionsFelt = emotionsFelt
        self.comment = comment
    }
    
    init(markTime : Date){
        self.markTime = markTime
    }
}

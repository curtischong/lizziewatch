	//
//  MarkEventObj.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

class MarkEventObj{
    var timeStartFillingForm : Date
    var timeEndFillingForm : Date
    var timeOfMark : Date
    var isReaction : Bool
    var anticipationStart : Date
    var timeOfEvent : Date
    var reactionEnd : Date
    var emotionsFelt : [Int]
    var comments : String
    var typeBiometricsViewed : [Int]
    
    init(timeStartFillingForm : Date,
    timeEndFillingForm : Date,
    timeOfMark : Date,
    isReaction : Bool,
    anticipationStart : Date,
    timeOfEvent : Date,
    reactionEnd : Date,
    emotionsFelt : [Int],
    comments : String,
    typeBiometricsViewed : [Int]){
        
        self.timeStartFillingForm = timeStartFillingForm
        self.timeEndFillingForm = timeEndFillingForm
        self.timeOfMark = timeOfMark
        self.isReaction = isReaction
        self.anticipationStart = anticipationStart
        self.timeOfEvent = timeOfEvent
        self.reactionEnd = reactionEnd
        self.emotionsFelt = emotionsFelt
        self.comments = comments
        self.typeBiometricsViewed = typeBiometricsViewed
    }
    
    init(timeOfMark : Date){
        let curDate = Date()
        
        self.timeStartFillingForm = curDate
        self.timeEndFillingForm = curDate
        self.timeOfMark = timeOfMark
        self.isReaction = true
        self.anticipationStart = curDate
        self.timeOfEvent = curDate
        self.reactionEnd = curDate
        self.emotionsFelt = [0,0,0,0,0,0,0,0]
        self.comments = ""
        self.typeBiometricsViewed = [0]
    }
}

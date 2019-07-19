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
    var markTime : Date
    var anticipate : Bool = true
    var startTime : Date
    var eventTime : Date
    var endTime : Date
    var emotionsFelt : [String : Int] = ["anger": -999,
                                         "contempt": -999,
                                         "disgust": -999,
                                         "fear": -999,
                                         "interest": -999,
                                         "joy": -999,
                                         "sad": -999,
                                         "surprise": -999]
    var comment : String = ""
    
    init(markTime : Date,
    anticipate : Bool,
    startTime : Date,
    eventTime : Date,
    endTime : Date,
    emotionsFelt : [String : Int],
    comment : String){
        
        self.markTime = markTime
        self.anticipate = anticipate
        self.startTime = startTime
        self.eventTime = eventTime
        self.endTime = endTime
        self.emotionsFelt = emotionsFelt
        self.comment = comment
    }
    
    init(markTime : Date){
        let curDate = Date()
        
        self.markTime = markTime
        self.startTime = curDate
        self.eventTime = curDate
        self.endTime = curDate
    }
}

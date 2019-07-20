//
//  EmotionEvalObj.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

class EmotionEvalObj{
    var uploaded : Bool = false
    var ts : Date = Date.from(year: 1970, month: 1, day: 1)!
    var accomplished : Int = -999
    var social : Int = -999
    var exhausted : Int = -999
    var tired : Int = -999
    var happy : Int = -999
    var comment : String = ""
    
    init(
    ts : Date,
    accomplished : Int,
    social : Int,
    exhausted : Int,
    tired : Int,
    happy : Int,
    comment : String){
        self.ts = ts
        self.accomplished = accomplished
        self.social = social
        self.exhausted = exhausted
        self.tired = tired
        self.happy = happy
        self.comment = comment
    }
}

//
//  EmotionEvalObj.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-03-01.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

class EmotionEvalObj{
    var timeStartFillingForm : Date
    var timeEndFillingForm : Date
    var normalEval : Int
    var socialEval : Int
    var exhaustedEval : Int
    var tiredEval : Int
    var happyEval : Int
    var comments : String
    
    init(timeStartFillingForm : Date,
    timeEndFillingForm : Date,
    normalEval : Int,
    socialEval : Int,
    exhaustedEval : Int,
    tiredEval : Int,
    happyEval : Int,
    comments : String){
        self.timeStartFillingForm = timeStartFillingForm
        self.timeEndFillingForm = timeEndFillingForm
        self.normalEval = normalEval
        self.socialEval = socialEval
        self.exhaustedEval = exhaustedEval
        self.tiredEval = tiredEval
        self.happyEval = happyEval
        self.comments = comments
    }
}

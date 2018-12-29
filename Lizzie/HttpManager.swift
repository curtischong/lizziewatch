//
//  HttpManager.swift
//  Lizzie
//
//  Created by Curtis Chong on 2018-12-29.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import Foundation
import Alamofire

class HttpManager{
    
    func uploadBioSamples(numSamples : Int,
                           endTimeOfQuery : Date,
                           samplesNames : [String],
                           samplesStartTime : [Date],
                           samplesEndTime : [Date],
                           samplesMeasurement : [Double]){
        let parameters: Parameters = [
            "numSamples" : numSamples,
            "endTimeOfQuery" : endTimeOfQuery,
            "samplesNames" : samplesNames,
            "samplesStartTime" : samplesStartTime,
            "samplesEndTime" : samplesEndTime,
            "samplesMeasurement" : samplesMeasurement
        ]

        //TODO: change the ip to the ip of the server
        AF.request("http://10.8.0.2:9000/watch_bio_samples",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                print("Request: \(String(describing: response.request))")   // original url request
                print("Response: \(String(describing: response.response))") // http url response
                print("Result: \(response.result)")                         // response serialization result
        }
    }

    func uploadMarkEvent(name : String,
                        desc : String,
                        timeOfMark : Date,
                        markTypeIsReaction : Bool,
                        startTimeLeadingToEvent : Date,
                        timeOfEvent : Date,
                        endTimeOfReaction : Date){
        let parameters: Parameters = [
            "name" : name,
            "desc" : desc,
            "timeOfMark" : timeOfMark,
            "markTypeIsReaction" : markTypeIsReaction,
            "startTimeLeadingToEvent" : startTimeLeadingToEvent,
            "timeOfEvent" : timeOfEvent,
            "endTimeOfReaction" : endTimeOfReaction
        ]
        
        //TODO: change the ip to the ip of the server
        AF.request("http://10.8.0.2:9000/watch_mark_event",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                print("Request: \(String(describing: response.request))")   // original url request
                print("Response: \(String(describing: response.response))") // http url response
                print("Result: \(response.result)")                         // response serialization result
        }
    }
}

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
    
    let SERVER_IP = "http://10.8.0.1:9000/"
    
    
    func json(from object: [Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    func uploadBioSamples(bioSamples : Array<BioSampleObj>){
        var dataPointNames = Array<String>()
        var startTimes = Array<String>()
        var endTimes = Array<String>()
        var measurements = Array<String>()
        
        
        for sample in bioSamples{
            
            let sampleStartTimeString = String(Double(round(1000*sample.startTime.timeIntervalSince1970)/1000))
            let sampleEndTimeString = String(Double(round(1000*sample.endTime.timeIntervalSince1970)/1000))
            let measurementString = String(sample.measurement)
            
            dataPointNames.append(sample.type)
            startTimes.append(sampleStartTimeString)
            endTimes.append(sampleEndTimeString)
            measurements.append(measurementString)
        }
        
        
        let parameters: Parameters = [
            "dataPointNames": json(from : dataPointNames) as Any,
            "startTimes": json(from : startTimes) as Any,
            "endTimes": json(from : endTimes) as Any,
            "measurements": json(from : measurements) as Any,
            ]
        // let ctx = self
        AF.request("http://10.8.0.1:9000/upload_bio_samples",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                NSLog("markEventSent! updating dateLastSyncedWithServer")
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
        AF.request(SERVER_IP + "watch_mark_event",
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

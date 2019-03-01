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
    let appContextFormatter = DateFormatter()
    
    init(){
        appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
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
    
    func uploadMarkEvent(){
        
    }
    
    func uploadEmotionEvaluation(emotionEvalObj : EmotionEvalObj){
        
        let parameters: Parameters = [
            "timeStartFillingForm": appContextFormatter.string(from: emotionEvalObj.timeStartFillingForm),
            "timeEndFillingForm": appContextFormatter.string(from: emotionEvalObj.timeEndFillingForm),
            "normalEval": String(emotionEvalObj.normalEval),
            "socialEval": String(emotionEvalObj.socialEval),
            "exhaustedEval": String(emotionEvalObj.exhaustedEval),
            "tiredEval": String(emotionEvalObj.tiredEval),
            "happyEval": String(emotionEvalObj.happyEval),
            "comments" : emotionEvalObj.comments
        ]
        //let config = readConfig()
        //print(config["ip"])
        let ctx = self
        
        AF.request("http://10.8.0.1:9000/upload_emotion_evaluation",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                NSLog("response received")
                //TODO: FIX THIS CALLBACK THING
                
                
                /*print("asdasd")
                 print(response.request)
                 if let status = response.response?.statusCode {
                 switch(status){
                 case 200:
                 print("example success")
                 default:
                 print("error with response status: \(status)")
                 }
                 }
                 
                 
                 print("ioioi")
                 if let result = response.result.value {
                 let JSON = result as! NSDictionary
                 print(JSON)
                 }else{
                 print(response.result)
                 }*/
                
                
                
                
                //print("Request: \(String(describing: response.request))")   // original url request
                //print("Response: \(String(describing: response.response))") // http url response
                
        }
    }
    
}

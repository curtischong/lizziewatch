//
//  HttpManager.swift
//  Lizzie
//
//  Created by Curtis Chong on 2018-12-29.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import Foundation
import Alamofire
//SwiftyJSON

class HttpManager{
    
    let SERVER_IP_PROD = "http://10.8.0.1:9000/"
    let SERVER_IP_DEV = "http://localhost:9000/"
    let ISDEV = true
    func getIp() -> String{
        if(ISDEV){
            return SERVER_IP_PROD
        }
        return SERVER_IP_DEV
    }
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
    
    func convertDate(date : Date) -> String{
        return String(Double(round(1000*date.timeIntervalSince1970)/1000))
    }
    
    func uploadBioSamples(bioSamples : Array<BioSampleObj>){
        var dataPointNames = Array<String>()
        var startTimes = Array<String>()
        var endTimes = Array<String>()
        var measurements = Array<String>()
        
        
        for sample in bioSamples{
            
            let sampleStartTimeString = convertDate(date: sample.startTime)
            let sampleEndTimeString = convertDate(date: sample.endTime)
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
        AF.request(getIp() + "upload_bio_samples",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                NSLog("markEventSent! updating dateLastSyncedWithServer")
        }
    }
    
    func uploadMarkEvent(markEventObj : MarkEventObj){

        var anticipate = "0"
        if(markEventObj.anticipate){
            anticipate = "1"
        }
        
        let emotionsFelt = markEventObj.emotionsFelt
        let comment = markEventObj.comment
        
        
        let parameters: Parameters = [
            "markTime": convertDate(date: markEventObj.markTime),
            "anticipate": anticipate,
            "startTime": convertDate(date: markEventObj.startTime), // The server only uses this if anticipate=false
            "eventTime": convertDate(date: markEventObj.eventTime),
            "endTime": convertDate(date: markEventObj.endTime),
            "fear": String(emotionsFelt["fear"]!),
            "joy": String(emotionsFelt["joy"]!),
            "anger": String(emotionsFelt["anger"]!),
            "sad": String(emotionsFelt["sad"]!),
            "disgust": String(emotionsFelt["disgust"]!),
            "surprise": String(emotionsFelt["surprise"]!),
            "contempt": String(emotionsFelt["contempt"]!),
            "interest": String(emotionsFelt["interest"]!),
            "comment" : comment
        ]
        
        // let ctx = self
        AF.request(getIp() + "upload_mark_event",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                NSLog("markEventSent! deleting MarkEvent")
                /*
                 print("Request: \(String(describing: response.request))")   // original url request
                 print("Response: \(String(describing: response.response))") // http url response
                 print("Result: \(response.result)")                         // response serialization result
                 */
                
                /*if let json = response.result.value {
                 print("JSON: \(json)") // serialized json response
                 }
                 
                 if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                 print("Data: \(utf8Text)") // original server data as UTF8 string
                 }*/
        }
    }
    
    func uploadEmotionEvaluation(emotionEvalObj : EmotionEvalObj){
        
        let parameters: Parameters = [
            "ts": appContextFormatter.string(from: emotionEvalObj.ts),
            "accomplishedEval": String(emotionEvalObj.accomplished),
            "socialEval": String(emotionEvalObj.social),
            "exhaustedEval": String(emotionEvalObj.exhausted),
            "tiredEval": String(emotionEvalObj.tired),
            "happyEval": String(emotionEvalObj.happy),
            "comments" : emotionEvalObj.comment,
            "evalLocation": "mobile"
        ]
        //let config = readConfig()
        //print(config["ip"])
        //let ctx = self
        
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

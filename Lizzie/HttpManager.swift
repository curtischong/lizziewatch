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
        AF.request("http://10.8.0.1:9000/upload_bio_samples",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                NSLog("markEventSent! updating dateLastSyncedWithServer")
        }
    }
    
    func uploadMarkEvent(markEventObj : MarkEventObj){
        
        let markTime = convertDate(date: markEventObj.markTime)
        
        var anticipate = "0"
        if(markEventObj.anticipate){
            anticipate = "1"
        }
        
        let startTime = convertDate(date: markEventObj.startTime)
        let eventTime = convertDate(date: markEventObj.eventTime)
        let endTime = convertDate(date: markEventObj.endTime)
        let emotionsFelt = markEventObj.emotionsFelt
        let comment = markEventObj.comment
        
        
        let fear = emotionsFelt[0]
        let joy = emotionsFelt[1]
        let anger = emotionsFelt[2]
        let sad = emotionsFelt[3]
        let disgust = emotionsFelt[4]
        let surprise = emotionsFelt[5]
        let contempt = emotionsFelt[6]
        let interest = emotionsFelt[7]
        
        
        let parameters: Parameters = [
            "markTime": markTime,
            "anticipate": anticipate,
            "startTime": startTime, // The server only uses this if anticipate=false
            "eventTime": eventTime,
            "endTime": endTime,
            "fear": fear,
            "joy": joy,
            "anger": anger,
            "sad": sad,
            "disgust": disgust,
            "surprise": surprise,
            "contempt": contempt,
            "interest": interest,
            "comment" : comment
        ]
        
        // let ctx = self
        AF.request(SERVER_IP + "upload_mark_event",
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
            "evalDatetime": appContextFormatter.string(from: emotionEvalObj.timeEndFillingForm),
            "accomplishedEval": String(emotionEvalObj.accomplishedEval),
            "socialEval": String(emotionEvalObj.socialEval),
            "exhaustedEval": String(emotionEvalObj.exhaustedEval),
            "tiredEval": String(emotionEvalObj.tiredEval),
            "happyEval": String(emotionEvalObj.happyEval),
            "comments" : emotionEvalObj.comments,
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

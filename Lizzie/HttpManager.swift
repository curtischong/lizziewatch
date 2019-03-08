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
        
        let timeStartFillingForm = convertDate(date: markEventObj.timeStartFillingForm)
        let timeEndFillingForm = convertDate(date: markEventObj.timeEndFillingForm)
        let timeOfMark = convertDate(date: markEventObj.timeOfMark)
        
        var isReaction = "0"
        if(markEventObj.isReaction){
            isReaction = "1"
        }
        
        let anticipationStart = convertDate(date: markEventObj.anticipationStart)
        let timeOfEvent = convertDate(date: markEventObj.timeOfEvent)
        let reactionEnd = convertDate(date: markEventObj.reactionEnd)
        let emotionsFelt = markEventObj.emotionsFelt
        let comments = markEventObj.comments
        let typeBiometricsViewed = json(from : markEventObj.typeBiometricsViewed) as Any
        
        let parameters: Parameters = [
            "timeStartFillingForm": timeStartFillingForm,
            "timeEndFillingForm": timeEndFillingForm,
            "timeOfMark": timeOfMark,
            "isReaction": isReaction,
            // The server only uses anticipationStart if isReaction = false
            "anticipationStart": anticipationStart,
            "timeOfEvent": timeOfEvent,
            "reactionEnd": reactionEnd,
            "emotionsFelt" : emotionsFelt,
            "comments" : comments,
            // for future reference we need to define what each index means: for now 0 means HR
            "typeBiometricsViewed" : typeBiometricsViewed //TODO: add more biometrics to view
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

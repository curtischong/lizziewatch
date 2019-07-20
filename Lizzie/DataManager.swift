//
//  DataManager.swift
//  
//
//  Created by Curtis Chong on 2019-03-01.
//

import Foundation
import CoreData
import UIKit

@available(iOS 11.0, *)
class DataManager{
    let context : NSManagedObjectContext!
    let MarkEventPhoneEntity :  NSEntityDescription!
    let EmotionEvalEntity :  NSEntityDescription!
    
    init(){
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        MarkEventPhoneEntity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
        EmotionEvalEntity = NSEntityDescription.entity(forEntityName: "EmotionEval", in: context)
        //markEventEntity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
    }
    
    func markEventToNSManagedObject(eventRef : NSManagedObject, markEvent : MarkEventObj){
        do {
            let emotionsFelt = try NSKeyedArchiver.archivedData(withRootObject: markEvent.emotionsFelt, requiringSecureCoding: false)
            
            eventRef.setValue(markEvent.markTime, forKey: "markTime")
            eventRef.setValue(markEvent.name, forKey: "name")
            eventRef.setValue(markEvent.anticipate, forKey: "anticipate")
            eventRef.setValue(markEvent.startTime, forKey: "startTime")
            eventRef.setValue(markEvent.eventTime, forKey: "eventTime")
            eventRef.setValue(markEvent.endTime, forKey: "endTime")
            eventRef.setValue(emotionsFelt, forKey: "emotionsFelt")
            eventRef.setValue(markEvent.comment, forKey: "comment")
            NSLog("Successfully converted markEvent to coredata entities")
        } catch let error {
            NSLog("Couldn't convert markEvent reviews to binary: \(error)")
        }
    }
    
    func emotionEvalToNSManagedObject(emotionRef : NSManagedObject, emotionEval : EmotionEvalObj){
        emotionRef.setValue(emotionEval.uploaded, forKey: "uploaded")
        emotionRef.setValue(emotionEval.ts, forKey: "ts")
        emotionRef.setValue(emotionEval.accomplished, forKey: "accomplished")
        emotionRef.setValue(emotionEval.social, forKey: "social")
        emotionRef.setValue(emotionEval.exhausted, forKey: "exhausted")
        emotionRef.setValue(emotionEval.tired, forKey: "tired")
        emotionRef.setValue(emotionEval.happy, forKey: "happy")
        emotionRef.setValue(emotionEval.comment, forKey: "comment")
    }
    
    func insertMarkEvents(markEvents : [MarkEventObj]) -> Bool{
        for markEvent in markEvents{
            if insertMarkEvent(markEvent: markEvent) == false{
                return false
            }
        }
        return true
    }
    
    func insertMarkEvent(markEvent : MarkEventObj) -> Bool{
        let eventRef = NSManagedObject(entity: MarkEventPhoneEntity!, insertInto: context)
        markEventToNSManagedObject(eventRef : eventRef, markEvent : markEvent)
        do {
            try context.save()
            NSLog("Successfully saved the current MarkEvent")
            return true
        } catch let error{
            NSLog("Couldn't save: the current markEvent with  error: \(error)")
            return false
        }
    }
    
    func insertEmotionEval(emotionEval : EmotionEvalObj) -> Bool{
        let emotionEvalRef = NSManagedObject(entity: EmotionEvalEntity!, insertInto: context)
        emotionEvalToNSManagedObject(emotionRef : emotionEvalRef, emotionEval : emotionEval)
        do {
            try context.save()
            NSLog("Successfully saved the current emotionEval")
            return true
        } catch let error{
            NSLog("Couldn't save: the current emotionEval with  error: \(error)")
            return false
        }
    }
    
    func deleteMarkEvent(markTime : Date) -> Bool{
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        fetchRequest.predicate = NSPredicate(format: "markTime == %@", markTime as NSDate)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try context.execute(deleteRequest)
            try context.save()
            NSLog("Deleted MarkEventPhone with time: \(markTime)")
            return true
        }catch let error{
            NSLog("Couldn't Delete MarkEventPhone with time \(markTime) with error: \(error)")
            return false
        }
    }
    
    func updateMarkEvent(markEvent : MarkEventObj){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        
        fetchRequest.predicate = NSPredicate(format: "markTime = %@",
                                             argumentArray: [markEvent.markTime])
        do {
            let results = try context.fetch(fetchRequest) as? [NSManagedObject]
            if results?.count != 0 {
                markEventToNSManagedObject(eventRef: results![0], markEvent : markEvent)
            }
        } catch {
            print("Fetch past skills for update Failed: \(error)")
        }
        
        do {
            try context.save()
        }
        catch {
            print("Saving past skills for update Failed: \(error)")
        }
    }
    
    
    func getAllEntities(entityName : String, predicate : NSPredicate?, sortDescriptors : [NSSortDescriptor]) -> [NSManagedObject]{
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        if predicate != nil{
            request.predicate = predicate
        }
        if sortDescriptors.count > 0{
            request.sortDescriptors = sortDescriptors
        }
        
        do{
            let result = try context.fetch(request)
            return result as! [NSManagedObject]
        } catch let error{
            NSLog("Couldn't load Skill rows with error: \(error)")
            return []
        }
    }
    
    func getAllMarkEvents() -> [MarkEventObj]{
        let sortDescriptor = NSSortDescriptor(key: "markTime", ascending: false)
        
        let entities = getAllEntities(entityName : "MarkEventPhone", predicate: nil, sortDescriptors : [sortDescriptor])
        
        
        var allEntities : [MarkEventObj] = []
        for entity in entities{
            let emotionsFeltNSData = entity.value(forKey: "emotionsFelt") as! NSData
            let emotionsFeltData = Data(referencing:emotionsFeltNSData)
            
            do{
                let emotionsFelt = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(emotionsFeltData) as? [String: Int]
                
                allEntities.append(MarkEventObj(markTime : entity.value(forKey: "markTime") as! Date,
                                                name: entity.value(forKey: "name") as! String,
                                                anticipate : entity.value(forKey: "anticipate") as! Bool,
                                                startTime : entity.value(forKey: "startTime") as! Date,
                                                eventTime : entity.value(forKey: "eventTime") as! Date,
                                                endTime : entity.value(forKey: "endTime") as! Date,
                                                emotionsFelt : emotionsFelt ?? ["anger": -999,
                                                                                "contempt": -999,
                                                                                "disgust": -999,
                                                                                "fear": -999,
                                                                                "interest": -999,
                                                                                "joy": -999,
                                                                                "sad": -999,
                                                                                "surprise": -999],
                                                comment: entity.value(forKey: "comment") as! String))
            }catch let error{
                NSLog("couldn't load binary from coredata: \(error)")
            }
        }
        return allEntities
    }
    
    func getAllMarkEvents() -> [MarkEventObj]{
        let sortDescriptor = NSSortDescriptor(key: "markTime", ascending: false)
        
        let entities = getAllEntities(entityName : "MarkEventPhone", predicate: nil, sortDescriptors : [sortDescriptor])
        
        
        var allEntities : [MarkEventObj] = []
        for entity in entities{
            let emotionsFeltNSData = entity.value(forKey: "emotionsFelt") as! NSData
            let emotionsFeltData = Data(referencing:emotionsFeltNSData)
            
            do{
                let emotionsFelt = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(emotionsFeltData) as? [String: Int]
                
                allEntities.append(MarkEventObj(markTime : entity.value(forKey: "markTime") as! Date,
                                                name: entity.value(forKey: "name") as! String,
                                                anticipate : entity.value(forKey: "anticipate") as! Bool,
                                                startTime : entity.value(forKey: "startTime") as! Date,
                                                eventTime : entity.value(forKey: "eventTime") as! Date,
                                                endTime : entity.value(forKey: "endTime") as! Date,
                                                emotionsFelt : emotionsFelt ?? ["anger": -999,
                                                                                "contempt": -999,
                                                                                "disgust": -999,
                                                                                "fear": -999,
                                                                                "interest": -999,
                                                                                "joy": -999,
                                                                                "sad": -999,
                                                                                "surprise": -999],
                                                comment: entity.value(forKey: "comment") as! String))
            }catch let error{
                NSLog("couldn't load binary from coredata: \(error)")
            }
        }
        return allEntities
    }
    
    func dropEmotionEvals(){
        // remove emotionEval rows
        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "EmotionEval")
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        do{
            try context.execute(deleteRequest2)
            try context.save()
            NSLog("Deleted EmotionEval rows")
        }catch let error{
            NSLog("Couldn't Delete EmotionEval rows with error: \(error)")
        }
    }
    
    func dropMarkEvents(){
        // remove MarkEvent rows
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        
        do{
            try context.execute(deleteRequest2)
            try context.save()
            NSLog("Deleted MarkEventPhone rows")
        }catch let error{
            NSLog("Couldn't Delete MarkEventPhone rows with error: \(error)")
        }
    }
    
    func dropAllRows(){
        dropEmotionEvals()
        dropMarkEvents()
    }
}

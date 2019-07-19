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
    //let markEventEntity : NSEntityDescription!
    
    init(){
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        MarkEventPhoneEntity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
        //markEventEntity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
    }
    
    func markEventToNSManagedObject(eventReference : NSManagedObject, markEvent : MarkEventObj){
        do {
            let emotionsFelt = try NSKeyedArchiver.archivedData(withRootObject: markEvent.emotionsFelt, requiringSecureCoding: false)
            
            eventReference.setValue(markEvent.markTime, forKey: "markTime")
            eventReference.setValue(markEvent.anticipate, forKey: "anticipate")
            eventReference.setValue(markEvent.startTime, forKey: "startTime")
            eventReference.setValue(markEvent.eventTime, forKey: "eventTime")
            eventReference.setValue(markEvent.endTime, forKey: "endTime")
            eventReference.setValue(emotionsFelt, forKey: "emotionsFelt")
            eventReference.setValue(markEvent.comment, forKey: "comment")
            NSLog("Successfully converted markEvent to coredata entities")
        } catch let error {
            NSLog("Couldn't convert markEvent reviews to binary: \(error)")
        }
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
        let eventReference = NSManagedObject(entity: MarkEventPhoneEntity!, insertInto: context)
        markEventToNSManagedObject(eventReference : eventReference, markEvent : markEvent)
        do {
            try context.save()
            NSLog("Successfully saved the current MarkEvent")
            return true
        } catch let error{
            NSLog("Couldn't save: the current markEvent with  error: \(error)")
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
                markEventToNSManagedObject(eventReference: results![0], markEvent : markEvent)
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
            allEntities.append(MarkEventObj(markTime : entity.value(forKey: "markTime") as! Date))
            
        }
        return allEntities
    }
    
    func dropAllRows(){
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
}

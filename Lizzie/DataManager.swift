//
//  DataManager.swift
//  
//
//  Created by Curtis Chong on 2019-03-01.
//

import Foundation
import CoreData
import UIKit

class DataManager{
    let context : NSManagedObjectContext!
    //let markEventEntity : NSEntityDescription!
    
    init(){
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        //markEventEntity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
    }
    
    func insertMarkEvents(markTimes : [Date]) -> Bool{
        let entity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
        for eventMark in markTimes {
            let curMark = NSManagedObject(entity: entity!, insertInto: context)
            curMark.setValue(eventMark, forKey: "markTime")
        }
        do {
            try context.save()
            NSLog("Successfully saved the current MarkEvent")
            return true
        } catch let error{
            NSLog("Couldn't save: the current EventMark with  error: \(error)")
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

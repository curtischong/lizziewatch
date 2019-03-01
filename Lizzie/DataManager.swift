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
    
    func deleteMarkEvent(timeOfMark : Date){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        fetchRequest.predicate = NSPredicate(format: "timeOfMark == %@", timeOfMark as NSDate)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try context.execute(deleteRequest)
            try context.save()
            NSLog("Deleted MarkEventPhone with time: \(timeOfMark)")
        }catch let error{
            NSLog("Couldn't Delete MarkEventPhone with time \(timeOfMark) with error: \(error)")
        }
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

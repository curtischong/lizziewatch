//
//  MarkEventPhone+CoreDataProperties.swift
//  
//
//  Created by Curtis Chong on 2018-12-27.
//
//

import Foundation
import CoreData


extension MarkEventPhone {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MarkEventPhone> {
        return NSFetchRequest<MarkEventPhone>(entityName: "MarkEventPhone")
    }

    @NSManaged public var timeOfMark: NSDate?

}

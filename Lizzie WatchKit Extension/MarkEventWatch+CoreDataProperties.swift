//
//  MarkEventWatch+CoreDataProperties.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//
//

import Foundation
import CoreData


extension MarkEventWatch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MarkEventWatch> {
        return NSFetchRequest<MarkEventWatch>(entityName: "MarkEventWatch")
    }

    @NSManaged public var timeOfMark: NSDate?

}

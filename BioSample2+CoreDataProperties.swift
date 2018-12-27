//
//  BioSample2+CoreDataProperties.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//
//

import Foundation
import CoreData


extension BioSample2 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BioSample2> {
        return NSFetchRequest<BioSample2>(entityName: "BioSample2")
    }

    @NSManaged public var dataPointName: String?
    @NSManaged public var endTime: NSDate?
    @NSManaged public var measurement: Double
    @NSManaged public var startTime: NSDate?

}

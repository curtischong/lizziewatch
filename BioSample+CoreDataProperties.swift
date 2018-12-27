//
//  BioSample+CoreDataProperties.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//
//

import Foundation
import CoreData


extension BioSample {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BioSample> {
        return NSFetchRequest<BioSample>(entityName: "BioSample")
    }

    @NSManaged public var dataPointName: String?
    @NSManaged public var endTime: NSDate?
    @NSManaged public var measurement: Double
    @NSManaged public var startTime: NSDate?

}

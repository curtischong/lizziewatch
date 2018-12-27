//
//  BioSamplePhone+CoreDataProperties.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//
//

import Foundation
import CoreData


extension BioSamplePhone {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BioSamplePhone> {
        return NSFetchRequest<BioSamplePhone>(entityName: "BioSamplePhone")
    }

    @NSManaged public var startTime: NSDate?
    @NSManaged public var dataPointName: String?
    @NSManaged public var measurement: Double
    @NSManaged public var endTime: NSDate?

}

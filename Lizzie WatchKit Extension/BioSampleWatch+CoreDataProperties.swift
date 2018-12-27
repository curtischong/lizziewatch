//
//  BioSampleWatch+CoreDataProperties.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//
//

import Foundation
import CoreData


extension BioSampleWatch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BioSampleWatch> {
        return NSFetchRequest<BioSampleWatch>(entityName: "BioSampleWatch")
    }

    @NSManaged public var dataPointName: String?
    @NSManaged public var measurement: Double
    @NSManaged public var startTime: NSDate?
    @NSManaged public var endTime: NSDate?

}

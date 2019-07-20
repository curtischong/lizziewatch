//
//  util.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-07-19.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return calendar.date(from: dateComponents) ?? nil
    }
}

//
//  AppSettings.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-01-05.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation


struct defaultsKeys {
    static let keyOne = "firstStringKey"
    static let keyTwo = "secondStringKey"
}

func setSettings(){
    let defaults = UserDefaults.standard
    defaults.set("Some String Value", forKey: defaultsKeys.keyOne)
    defaults.set("Another String Value", forKey: defaultsKeys.keyTwo)
}

func getSettings(){
    let defaults = UserDefaults.standard
    if let stringOne = defaults.string(forKey: defaultsKeys.keyOne) {
        print(stringOne) // Some String Value
    }
    if let stringTwo = defaults.string(forKey: defaultsKeys.keyTwo) {
        print(stringTwo) // Another String Value
    }
}

//
//  AppSettings.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-01-05.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

struct ConfigObj {
    var dateLastSyncedWithWatch : Date?//= "firstStringKey"
    var dateLastSyncedWithServer : Date?// = "secondStringKey"
    
    init(dateLastSyncedWithWatch: Date? = nil, dateLastSyncedWithServer: Date? = nil) {
        self.dateLastSyncedWithWatch = dateLastSyncedWithWatch
        self.dateLastSyncedWithServer = dateLastSyncedWithServer
    }
}

func setSettings(curConfigObj : ConfigObj){
    //defaults.set("Another String Value", forKey: appContextFormatter.string( from: curConfigObj.dateLastSyncedWithServer!))
    let appContextFormatter = DateFormatter()
    appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let defaults = UserDefaults.standard
    if(curConfigObj.dateLastSyncedWithWatch != nil){
        defaults.set(appContextFormatter.string( from: curConfigObj.dateLastSyncedWithWatch!), forKey: "dateLastSyncedWithWatch")
    }
    if(curConfigObj.dateLastSyncedWithServer != nil){
        defaults.set(appContextFormatter.string( from: curConfigObj.dateLastSyncedWithServer!), forKey: "dateLastSyncedWithServer")
    }
}

func getSettings() -> ConfigObj{
    //defaults.set("Another String Value", forKey: appContextFormatter.string( from: curConfigObj.dateLastSyncedWithServer!))
    let appContextFormatter = DateFormatter()
    appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    
    var newConfigObj = ConfigObj()
    
    let defaults = UserDefaults.standard
    if let dateLastSyncedWithWatch = defaults.string(forKey: "dateLastSyncedWithWatch") {
        newConfigObj.dateLastSyncedWithWatch = appContextFormatter.date(from: dateLastSyncedWithWatch)
    }
    if let dateLastSyncedWithServer = defaults.string(forKey: "dateLastSyncedWithServer") {
        newConfigObj.dateLastSyncedWithServer = appContextFormatter.date(from: dateLastSyncedWithServer)
    }
    return newConfigObj
}

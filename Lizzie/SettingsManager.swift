//
//  AppSettings.swift
//  Lizzie
//
//  Created by Curtis Chong on 2019-01-05.
//  Copyright © 2019 Thomas Paul Mann. All rights reserved.
//

import Foundation

class SettingsManager {
    var defaults : UserDefaults!
    var dateLastSyncedWithWatch : Date?//= "firstStringKey"
    var dateLastSyncedWithServer : Date?// = "secondStringKey"
    let appContextFormatter = DateFormatter()
    
    init(dateLastSyncedWithWatch: Date? = nil, dateLastSyncedWithServer: Date? = nil) {
        appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        defaults = UserDefaults.standard
        self.dateLastSyncedWithWatch = dateLastSyncedWithWatch
        self.dateLastSyncedWithServer = dateLastSyncedWithServer
        self.getSavedSettings()
    }

    func saveSettings(){
        //defaults.set("Another String Value", forKey: appContextFormatter.string( from: curConfigObj.dateLastSyncedWithServer!))
        let defaults = UserDefaults.standard
        if(self.dateLastSyncedWithWatch != nil){
            defaults.set(appContextFormatter.string( from: self.dateLastSyncedWithWatch!), forKey: "dateLastSyncedWithWatch")
        }
        if(self.dateLastSyncedWithServer != nil){
            defaults.set(appContextFormatter.string( from: self.dateLastSyncedWithServer!), forKey: "dateLastSyncedWithServer")
        }
    }

    func getSavedSettings(){
        if let dateLastSyncedWithWatch = defaults.string(forKey: "dateLastSyncedWithWatch") {
            self.dateLastSyncedWithWatch = appContextFormatter.date(from: dateLastSyncedWithWatch)
        }
        if let dateLastSyncedWithServer = defaults.string(forKey: "dateLastSyncedWithServer") {
            self.dateLastSyncedWithServer = appContextFormatter.date(from: dateLastSyncedWithServer)
        }
    }
}

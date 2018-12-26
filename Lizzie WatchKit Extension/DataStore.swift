//
//  DataStore.swift
//  Lizzie WatchKit Extension
//
//  Created by Curtis Chong on 2018-12-25.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import Foundation

class DataStore: NSObject {
    let unsynced = "dataStore.txt"
    let syncData = "stuff"


    func saveToFile() -> (URL){
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(unsynced)
            
            //writing
            do {
                try syncData.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                NSLog("Sorry couldn't write data file")
            }
            return fileURL
        }
        return URL(string: "Feelsbad")!
    }
    
    func readFromFile(dataStoreUrl: URL){
        //TODO: fix this read file error
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: dataStoreUrl.path) {
            //reading
            do {
                let text2 = try String(contentsOf: dataStoreUrl, encoding: .utf8)
                print(text2)
            }
            catch {
                NSLog("Sorry couldn't read data file")
            }
        }else{
            NSLog("DataStore file doesn't exist")
        }
    }
}

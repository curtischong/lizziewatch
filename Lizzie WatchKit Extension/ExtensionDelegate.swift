//
//  ExtensionDelegate.swift
//  Heart Control WatchKit Extension
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import WatchKit
import CoreData

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        backgroundTasks.forEach { (task) in
            // Process the background task
            
            // Be sure to complete each task when finished processing.
            task.setTaskCompleted()
        }
    }
    
    lazy var persistentContainer: NSPersistentContainer? = {
        objc_sync_enter(self)
        let container = NSPersistentContainer( name: "BioSamplesWatch" )
        container.loadPersistentStores { _, error in
            if error != nil { fatalError( " Core Data error: \( error! )" ) }
        }
        objc_sync_exit(self)
        return container
    }()
    
    /*
    lazy var persistentContainer: NSPersistentContainer = {
     objc_sync_enter(self)
        
        let container = NSPersistentContainer(name: "BioSamplesWatch")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                
                fatalError("Unresolved error, \((error as NSError))")
            }
        })
     objc_sync_exit(self)
        return container
    }()*/
    /*
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        objc_sync_enter(self)
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("moduleName.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]) // maybe change after pre - production
        } catch {
        // Report any error we got.
        var dict = [String: AnyObject]()
        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
        dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
        dict[NSUnderlyingErrorKey] = error as NSError
        let wrappedError = NSError(domain: "ERROR_DOMAIN", code: 9999, userInfo: dict)
        
        #if DEBUG
        NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        #endif
        abort()
        }
        
        objc_sync_exit(self)
        
        return coordinator
    }()*/

}

//
//  AppDelegate.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import UIKit
import HealthKit
import CoreData

@UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties

    private let healthStore = HKHealthStore()

    var window: UIWindow?

    // MARK: - Lifecycle

    private func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        // Authorize access to health data for watch.
        healthStore.handleAuthorizationForExtension { success, error in
            NSLog("Authentication status for healthkit: \(success)")
        }
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "BioSamplePhone")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                
                fatalError("Unresolved error, \((error as NSError).userInfo)")
            }
        })
        return container
    }()

}


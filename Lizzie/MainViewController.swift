//
//  MainViewController.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//

import UIKit
import CoreData

//TODO: find a way to show the shared folder and move the healthKitDataPoint to it
class MainViewController: UIViewController {
    

    @IBOutlet weak var phoneDataStoreCnt: UILabel!
    
    //MARK: Properties
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //https://stackoverflow.com/questions/37810967/how-to-apply-the-type-to-a-nsfetchrequest-instance/37811827
        //let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Level")
        // update the number of items not synced:
        
        
        let curSample = HealthKitDataPoint(
            dataPointName: "random name",
            startTime: Date(),
            endTime: Date() + 5,
            measurement: 5.0
        )
        self.storeBioSamplePhone(bioSample : curSample)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSamplePhone")
        do{
            let result = try context.fetch(request)
            phoneDataStoreCnt.text = String(result.count)
        } catch let error{
            NSLog("Couldn't access CoreData: \(error)")
        }
        
    }
    
    //MARK: Actions
    
    // Saves the bioSamples from the watch to the phone's DataCore
    private func storeBioSamplePhone(bioSample : HealthKitDataPoint){
        let entity = NSEntityDescription.entity(forEntityName: "BioSamplePhone", in: context)
        let healthSample = NSManagedObject(entity: entity!, insertInto: context)
        healthSample.setValue(bioSample.dataPointName, forKey: "dataPointName")
        healthSample.setValue(bioSample.startTime, forKey: "startTime")
        healthSample.setValue(bioSample.endTime, forKey: "endTime")
        healthSample.setValue(bioSample.measurement, forKey: "measurement")
        
        do {
            try context.save()
        } catch let error{
            NSLog("Couldn't save: \(bioSample.printVals()) with  error: \(error)")
        }
    }
    
    // Saves the bioSamples the phone's DataCore to the server
    private func uploadBioSample(){
        
    }
    
    
    private func fetchHeartrate(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSamplePhone")
        //request.predicate = NSPredicate(format: "age = %@", "12")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
            print(data.value(forKey: "username") as! String)
        }
        
        } catch let error{
        
            print("Failed Fetching Heartrate \(error)")
        }
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

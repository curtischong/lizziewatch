//
//  MainViewController.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.
//

import UIKit
import CoreData
import WatchConnectivity
import Alamofire

//TODO: find a way to show the shared folder and move the healthKitDataPoint to it
class MainViewController: UIViewController , WCSessionDelegate{
    

    @IBOutlet weak var phoneDataStoreCnt: UILabel!

    @IBOutlet weak var syncToPhoneStateLabel: UILabel!
    
    var syncToPhoneState = false
    
    //MARK: Properties
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
    var session: WCSession?
    let formatter = DateFormatter()
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        //https://stackoverflow.com/questions/37810967/how-to-apply-the-type-to-a-nsfetchrequest-instance/37811827
        //let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Level")
        // update the number of items not synced:
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }

        
        
        
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
    
    private func alertUser(message: String){
        let alertController = UIAlertController(title: "Action Required", message:
            "Hello, world!", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func syncWatchData(_ sender: Any) {
        if let validSession = session {
            let iPhoneAppContext = ["event" : "syncData", "TimeOfTransfer" : formatter.string(from: Date())]
            
            do {
                try validSession.updateApplicationContext(iPhoneAppContext)
                NSLog("Told watch to sync data")
                //syncToPhoneStateLabel.text = "told watch sync"
            } catch let error{
                //TODO: update a ui element when this happens
                //alertUser(message : "Please Turn on Watch to Pair")
                //syncToPhoneStateLabel.text = "fail tell watch sync \(error)"
            }
        }
    }
    
    
    
    func processApplicationContext() {
        let watchContext = session!.receivedApplicationContext as? [String : String]
        if(watchContext != nil){
            //syncToPhoneStateLabel.text = watchContext!["event"]
            /*
            if (watchContext!["event"] == "yolo") {
                syncToPhoneStateLabel.text = "yolooooo"
            } else if (watchContext!["event"] == "yasdasdolo"){
                
            }else {
                NSLog("Invalid iPhoneContext event received: \(String(describing: watchContext!["event"]))")
            }*/
        }else{
            NSLog("ERROR THE WATCH CONTEXT IS NIL")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async() {
            NSLog("received application context!")
            self.processApplicationContext()
        }
    }
    
    // this recieves a dictionary of objects from the watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async{
            //self.syncToPhoneStateLabel.text = "syncing"
            // in the future I might want to cast each event into a specific struct

            let eventType = userInfo["event"] as! String
            if(eventType == "dataStoreBioSamples"){
                let numItems = userInfo["numItems"] as! Int
                NSLog("Number of items received: \(numItems)")
                let sampleNames = userInfo["samplesNames"] as! [String]
                for i in 0..<numItems {
                    self.syncToPhoneStateLabel.text = sampleNames[i]
                }
                //we want to avoid casting it to healthkit data point to save battery
                /*
                if(numItems > 0){
                    //let numSamples = userInfo["numSamples"]
                    let samples = userInfo["samples"] as! Array<HealthKitDataPoint>
                    for (index, sample) in samples.enumerated() {
                        print("Item \(index): \(sample.printVals())")
                    }
                }*/
            }else{
                NSLog("Can't find event for \(eventType)")
            }
            /*DispatchQueue.main.async {
             // make sure to put on the main queue to update UI!
             }*/
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
    
    
    // THESE FUNCTIONS ARE ALL WRONG WE NEED TO SEND MORE THAN ONE SAMPLE AT ONCE
    // ANOTHER THING, we don't send markEvents. we send the handeled version of those
    private func sendBioSampleSnapshot(bioSample: HealthKitDataPoint) {
        
        let parameters: Parameters = [
            "dataPointName": bioSample.dataPointName,
            "startTime": bioSample.startTime,
            "endTime": bioSample.endTime,
            "measurement": bioSample.measurement
        ]
        //let config = readConfig()
        //print(config["ip"])
        
        // NOTE: I AM SENDING THIS TO MY LOCAL SERVER ATM
        // IF THIS REQUEST DOESN'T WORK MAKE SURE YOU ARE CONNECTED TO THE VPN
        AF.request("http://10.8.0.2:9000/watch_bio_snapshot",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding()
            ).responseJSON { response in
                
                print("Request: \(String(describing: response.request))")   // original url request
                print("Response: \(String(describing: response.response))") // http url response
                print("Result: \(response.result)")                         // response serialization result
                
                /*if let json = response.result.value {
                 print("JSON: \(json)") // serialized json response
                 }
                 
                 if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                 print("Data: \(utf8Text)") // original server data as UTF8 string
                 }*/
        }
    }
    
    private func sendMarkEventSnapshot(markEvent: HealthKitDataPoint) {
        
    }
}

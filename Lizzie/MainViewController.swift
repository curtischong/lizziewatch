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
class MainViewController: UIViewController , WCSessionDelegate, UITableViewDelegate{
    
    
    @IBOutlet weak var syncToPhoneStateLabel: UILabel!
    @IBOutlet weak var bioSampleCntPhone: UILabel!
    @IBOutlet weak var markEventCntPhone: UILabel!
    
    @IBOutlet weak var markEventTable: UITableView!
    
    var syncToPhoneState = false
    private let dataSource = DataSource()
    
    
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
        

        // update the number of items not synced:
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        updateBioSampleCnt()
        updateMarkEventCnt()
        
        dataSource.movies = ["Terminator","Back To The Future","The Dark Knight"]
        markEventTable.dataSource = dataSource
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alertController = UIAlertController(title: "Hint", message: "You have selected row \(indexPath.row).", preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        
        alertController.addAction(alertAction)
        
        present(alertController, animated: true, completion: nil)
        
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
                NSLog("Couldn't tell watch to sync with error: \(error)")
            }
        }
    }
    
    
    
    func processApplicationContext() {
        let watchContext = session!.receivedApplicationContext as? [String : String]
        if(watchContext != nil){
            NSLog("Received random application context ¯\\_(ツ)_/¯")
        }else{
            NSLog("ERROR THE WATCH CONTEXT IS NIL")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async(){
            NSLog("received application context!")
            self.processApplicationContext()
        }
    }
    
    // this recieves a dictionary of objects from the watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async(){
            self.syncToPhoneStateLabel.text = "syncing"
            // in the future I might want to cast each event into a specific struct

            let eventType = userInfo["event"] as! String
            if(eventType == "dataStoreBioSamples"){
                let numItems = userInfo["numItems"] as! Int
                NSLog("Number of items received: \(numItems)")
                
                self.storeBioSamplePhone(
                    numSamples : userInfo["numItems"] as! Int,
                    endTimeOfQuery : userInfo["endTimeOfQuery"] as! Date,
                    samplesNames : userInfo["samplesNames"] as! [String],
                    samplesStartTime : userInfo["samplesStartTime"] as! [Date],
                    samplesEndTime : userInfo["samplesEndTime"] as! [Date],
                    samplesMeasurement : userInfo["samplesMeasurement"] as! [Double]
                )
            }else if(eventType == "dataStoreMarkEvents"){
                let numItems = userInfo["numItems"] as! Int
                NSLog("Number of items received: \(numItems)")
                
                self.storeMarkEventPhone(timeOfMarks : userInfo["timeOfMarks"] as! [Date])
                
            }else{
                NSLog("Can't find event for \(eventType)")
            }
        }
    }

    
    // TODO: decrease lag and potential for crashing by using the batch insert method described here:
    // https://stackoverflow.com/questions/4145888/ios-coredata-batch-insert
    private func storeBioSamplePhone(numSamples : Int,
                                     endTimeOfQuery : Date,
                                     samplesNames : [String],
                                     samplesStartTime : [Date],
                                     samplesEndTime : [Date],
                                     samplesMeasurement : [Double]){
        
        let entity = NSEntityDescription.entity(forEntityName: "BioSamplePhone", in: context)
        
        for i in 0..<numSamples {
            let curBio = NSManagedObject(entity: entity!, insertInto: context)
            curBio.setValue(samplesNames[i], forKey: "dataPointName")
            curBio.setValue(samplesStartTime[i], forKey: "startTime")
            curBio.setValue(samplesEndTime[i], forKey: "endTime")
            curBio.setValue(samplesMeasurement[i], forKey: "measurement")
        }
        
        do {
            try context.save()
            self.updateBioSampleCnt()
            NSLog("Successfully saved the current BioSample")
            self.syncToPhoneStateLabel.text = "synced"
        } catch let error{
            NSLog("Couldn't save: the current EventMark with  error: \(error)")
        }
    }
    
    private func storeMarkEventPhone(timeOfMarks : [Date]){
        let entity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
        for eventMark in timeOfMarks {
            let curMark = NSManagedObject(entity: entity!, insertInto: context)
            curMark.setValue(eventMark, forKey: "timeOfMark")
        }
        do {
            try context.save()
            self.updateMarkEventCnt()
            NSLog("Successfully saved the current MarkEvent")
            self.syncToPhoneStateLabel.text = "synced"
        } catch let error{
            NSLog("Couldn't save: the current EventMark with  error: \(error)")
        }
    }
    
    private func updateBioSampleCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSamplePhone")
        do{
            let result = try context.fetch(request)
            bioSampleCntPhone.text = String(result.count)
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    private func updateMarkEventCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        do{
            let result = try context.fetch(request)
            markEventCntPhone.text = String(result.count)
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    
    private func dropAllRows(){
        //TODO: could merge the do catch... maybe
        // remove BioSample rows
        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        do{
            try context.execute(deleteRequest1)
            try context.save()
            NSLog("Deleted BioSampleWatch rows")
            updateBioSampleCnt()
        }catch let error{
            NSLog("Couldn't Delete BioSampleWatch rows with error: \(error)")
        }
        
        // remove MarkEvent rows
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSampleWatch")
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        
        do{
            try context.execute(deleteRequest2)
            try context.save()
            NSLog("Deleted MarkEvent rows")
            updateBioSampleCnt()
        }catch let error{
            NSLog("Couldn't Delete MarkEvent rows with error: \(error)")
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

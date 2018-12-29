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
    @IBOutlet weak var dateLastSyncLabel: UILabel!
    
    var syncToPhoneState = false
    private let dataSource = DataSource()
    
    
    //MARK: Properties
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
    var session: WCSession?
    let appContextFormatter = DateFormatter()
    let displayDateFormatter = DateFormatter()
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        markEventTable.delegate = self

        // update the number of items not synced:
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        updateBioSampleCnt()
        updateMarkEventCnt()
        loadMarkEventRows()
        // dataSource.movies = ["Terminator","Back To The Future","The Dark Knight"]
        //markEventTable.dataSource = dataSource
        
        // Used only in testing
        // dropAllRows()
        
        //TODO: I need to have a default "last synced" variable stored in system memory. so if the watch isn't on, I still get the date
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
        NSLog("\(dataSource.markEvents[indexPath.row])")
    }
    
    //prepareForSegue:sender:
    
    /*
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alertController = UIAlertController(title: "Hint", message: "You have selected row \(indexPath.row).", preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        
        alertController.addAction(alertAction)
        
        present(alertController, animated: true, completion: nil)
    }*/
    
    func removeMarkEvent(timeOfMark : Date){
        //TODO: google for an alternative to BatchDelete
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        fetchRequest.predicate = NSPredicate(format: "timeOfMark == %@", timeOfMark as NSDate)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try context.execute(deleteRequest)
            try context.save()
            NSLog("Deleted MarkEventPhone with timeOfMark: \(appContextFormatter.string(from: timeOfMark)) ")
            
            //not sure if the mainview controller reloads
            //updateMarkEventCnt()
            //loadMarkEventRows()
        }catch let error{
            NSLog("Couldn't Delete MarkEventPhone of time\(appContextFormatter.string(from: timeOfMark)) with error: \(error)")
        }
    }
    
    
    private func loadMarkEventRows(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        
        do{
            let result = try context.fetch(request)
            var markEvents = Array<Date>()
            
            for sample in result as! [NSManagedObject] {
                markEvents.append(sample.value(forKey: "timeOfMark") as! Date)
            }
            dataSource.markEvents = markEvents
            markEventTable.dataSource = dataSource
            markEventTable.reloadData()
        } catch let error{
            NSLog("Couldn't load MarkEventPhone rows with error: \(error)")
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
    
    @IBAction func syncWatchData(_ sender: Any) {
        if let validSession = session {
            let iPhoneAppContext = ["event" : "syncData", "TimeOfTransfer" : appContextFormatter.string(from: Date())]
            
            do {
                try validSession.updateApplicationContext(iPhoneAppContext)
                NSLog("Told watch to sync data")
                //syncToPhoneStateLabel.text = "told watch sync"
            } catch let error{
                
                //TODO: update a ui element when this happens
                NSLog("Couldn't tell watch to sync with error: \(error)")
            }
        }
    }
    
    func processApplicationContext() {
        
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
            // in the future I might want to cast each event into a specific struct
            
            let eventType = userInfo["event"] as! String
            
            if(eventType == "updateLastSync"){
                self.updateLastSync(userInfo : userInfo)
            }else if(eventType == "dataStoreBioSamples"){
                self.dataStoreBioSamples(userInfo: userInfo)
            }else if(eventType == "dataStoreMarkEvents"){
                self.dataStoreMarkEvents(userInfo: userInfo)
            }else{
                NSLog("Invalid watchContext event received: \(eventType)")
            }
        }
    }
    
    func updateLastSync(userInfo : [String : Any]){
        self.syncToPhoneStateLabel.text = "Synced"
        dateLastSyncLabel.text = userInfo["selectBeforeTime"] as? String
    }
    
    func dataStoreBioSamples(userInfo : [String : Any]){
        self.syncToPhoneStateLabel.text = "Syncing"
        let endTimeOfQuery = userInfo["endTimeOfQuery"] as! Date
        self.dateLastSyncLabel.text = self.displayDateFormatter.string(from: endTimeOfQuery)
        
        let numItems = userInfo["numItems"] as! Int
        NSLog("Number of items received: \(numItems)")
        
        self.storeBioSamplePhone(
            numSamples : userInfo["numItems"] as! Int,
            endTimeOfQuery : endTimeOfQuery,
            samplesNames : userInfo["samplesNames"] as! [String],
            samplesStartTime : userInfo["samplesStartTime"] as! [Date],
            samplesEndTime : userInfo["samplesEndTime"] as! [Date],
            samplesMeasurement : userInfo["samplesMeasurement"] as! [Double]
        )
    }
    
    func dataStoreMarkEvents(userInfo : [String : Any]){
        self.syncToPhoneStateLabel.text = "Syncing"
        let endTimeOfQuery = userInfo["endTimeOfQuery"] as! Date
        self.dateLastSyncLabel.text = self.displayDateFormatter.string(from: endTimeOfQuery)
        
        let numItems = userInfo["numItems"] as! Int
        NSLog("Number of items received: \(numItems)")
        
        self.storeMarkEventPhone(timeOfMarks : userInfo["timeOfMarks"] as! [Date], endTimeOfQuery : endTimeOfQuery)
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
            self.syncToPhoneStateLabel.text = "Synced"
            
            // Tell the phone that the transfer finished
            // TODO: if this fails I might want to ask the phone for another batch
            // Note: I'm not sure if this force unwrap is safe
            let dataStorePackage = ["event" : "finishedSyncing",
                                     "syncDataType": "dataStoreBioSamples",
                                     "selectBeforeTime": endTimeOfQuery] as [String : Any]
            session!.transferUserInfo(dataStorePackage)
        } catch let error{
            NSLog("Couldn't save: the current BioSample with  error: \(error)")
        }
    }
    
    // Stores the received data into the phone's coredata, updates the UI (MarkEvent Table View), and notifies the watch it's done syncing
    private func storeMarkEventPhone(timeOfMarks : [Date], endTimeOfQuery : Date){
        let entity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
        for eventMark in timeOfMarks {
            let curMark = NSManagedObject(entity: entity!, insertInto: context)
            curMark.setValue(eventMark, forKey: "timeOfMark")
        }
        do {
            try context.save()
            self.updateMarkEventCnt()
            NSLog("Successfully saved the current MarkEvent")
            self.syncToPhoneStateLabel.text = "Synced"
            
            // TODO: note: the concerns raised above applies to here too
            let dataStorePackage = ["event" : "finishedSyncing",
                                     "syncDataType": "dataStoreMarkEvents",
                                     "selectBeforeTime": endTimeOfQuery] as [String : Any]
            
            session!.transferUserInfo(dataStorePackage)
            loadMarkEventRows()
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
        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSamplePhone")
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        do{
            try context.execute(deleteRequest1)
            try context.save()
            NSLog("Deleted BioSamplePhone rows")
            updateBioSampleCnt()
        }catch let error{
            NSLog("Couldn't Delete BioSamplePhone rows with error: \(error)")
        }
        
        // remove MarkEvent rows
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        
        do{
            try context.execute(deleteRequest2)
            try context.save()
            NSLog("Deleted MarkEventPhone rows")
            updateMarkEventCnt()
        }catch let error{
            NSLog("Couldn't Delete MarkEventPhone rows with error: \(error)")
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
        

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        NSLog("Received event for: \(segue.identifier)")
        /*if segue.identifier == "evalEmotionSegue"{
            if segue.destination is EvalEmotionViewController {

            }
        }else if(segue.identifier == "contextualizeMarkEventSegue"){
            if let destinationVC = segue.destination as? ViewController {
                //destinationVC.markEventDate = counter
            }
        }*/
    }
    
    @IBAction func unwindEmotionView(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func gotoEvalEmotionSegue(_ sender: UIButton) {
        performSegue(withIdentifier: "evalEmotionSegue", sender: self)
    }
    
    private func sendMarkEventSnapshot(markEvent: HealthKitDataPoint) {
        
    }
}

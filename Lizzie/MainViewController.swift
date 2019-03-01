//
//  MainViewController.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.


import UIKit
import WatchConnectivity
import HealthKit

//TODO: find a way to show the shared folder and move the healthKitDataPoint to it
class MainViewController: UIViewController , WCSessionDelegate, UITableViewDelegate{
    
    
    @IBOutlet weak var syncToPhoneStateLabel: UILabel!
    @IBOutlet weak var markEventCntPhone: UILabel!
    
    @IBOutlet weak var markEventTable: UITableView!
    @IBOutlet weak var dateLastSyncLabel: UILabel!
    
    @IBOutlet weak var uploadBioSamplesButton: UIButton!
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
    let settingsManager = SettingsManager()
    let httpManager = HttpManager()
    let hkManager = HKManager()
    let dataManager = DataManager()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
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
        updateMarkEventCnt()
        loadMarkEventRows()
        NSLog("Main View Loaded")
        
        if(settingsManager.dateLastSyncedWithWatch != nil){
            dateLastSyncLabel.text = displayDateFormatter.string(from: settingsManager.dateLastSyncedWithWatch!)
        }
        if (authenticateForHealthstoreData()){
            
            NSLog("Querying for healthkit datapoints")
            let endDate = Date()
            var startDate = Date()
            if(settingsManager.dateLastSyncedWithServer == nil){
                NSLog("The app has never synced with the server. Sending all the biopoints from the last week")
                // select all the data from the past week for good measure
                startDate = endDate.addingTimeInterval(-24 * 60 * 60 * 7)
            }else{
                // query for points an hour before the last sync bc points may start before the endDate of the query
                startDate = settingsManager.dateLastSyncedWithServer!.addingTimeInterval(-60 * 60)
            }
            
            let samples = hkManager.queryBioSamples(startDate : startDate, endDate : endDate)
            self.handleBioSamples(samples : samples, startDate : startDate, endDate : endDate)
        }
        
        // Used only in testing
        //dataManager.dropAllRows()
        //updateMarkEventCnt()
    }
    
    //MARK: Actions
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fillMarkEvent(timeOfMark : dataSource.markEvents[indexPath.row].timeOfMark)
    }
    
    func loadMarkEventRows(){
        let markEvents = dataManager.getAllMarkEvents()
        dataSource.markEvents = markEvents
        markEventTable.dataSource = dataSource
        markEventTable.reloadData()

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
    
    func dataStoreMarkEvents(userInfo : [String : Any]){
        self.updateMarkEventCnt()
        self.syncToPhoneStateLabel.text = "Syncing"
        let endTimeOfQuery = userInfo["endTimeOfQuery"] as! Date
        self.dateLastSyncLabel.text = self.displayDateFormatter.string(from: endTimeOfQuery)
        
        let numItems = userInfo["numItems"] as! Int
        NSLog("Number of items received: \(numItems)")
        
        self.storeMarkEventPhone(timeOfMarks : userInfo["timeOfMarks"] as! [Date], endTimeOfQuery : endTimeOfQuery)
    }
    
    
    // Stores the received data into the phone's coredata, updates the UI (MarkEvent Table View), and notifies the watch it's done syncing
    private func storeMarkEventPhone(timeOfMarks : [Date], endTimeOfQuery : Date){
        if(dataManager.insertMarkEvents(timeOfMarks : timeOfMarks)){
            self.syncToPhoneStateLabel.text = "Synced"
            
            settingsManager.dateLastSyncedWithWatch = endTimeOfQuery
            settingsManager.saveSettings()
            
            // TODO: note: the concerns raised above applies to here too
            let dataStorePackage = ["event" : "finishedSyncing",
                                    "syncDataType": "dataStoreMarkEvents",
                                    "selectBeforeTime": endTimeOfQuery] as [String : Any]
            
            session!.transferUserInfo(dataStorePackage)
            loadMarkEventRows()
        }
    }
    
    func updateMarkEventCnt(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MarkEventPhone")
        do{
            let result = try context.fetch(request)
            markEventCntPhone.text = String(result.count)

            if(result.count == 0){
                // TODO: replace this button with something more useful
                //uploadBioSamplesButton.isHidden = false
                uploadBioSamplesButton.isHidden = true
                markEventTable.isHidden = true
            }else{
                uploadBioSamplesButton.isHidden = true
                markEventTable.isHidden = false
            }
        } catch let error{
            NSLog("Couldn't access CoreDataWatch: \(error)")
        }
    }
    
    
    // MARK: - Navigation
        
    @IBAction func markEventButtonPress(_ sender: UIButton) {
        let entity = NSEntityDescription.entity(forEntityName: "MarkEventPhone", in: context)
        let curMark = NSManagedObject(entity: entity!, insertInto: context)
        curMark.setValue(Date(), forKey: "timeOfMark")
        
        do {
            try context.save()
            self.updateMarkEventCnt()
            loadMarkEventRows()
            NSLog("Successfully saved the current MarkEvent")
        } catch let error{
            NSLog("Couldn't save: the current MarkEvent with  error: \(error)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "evalEmotionSegue"{ // no params to pass as of this version
            if segue.destination is EvalEmotionViewController {
                
            }
        }else if(segue.identifier == "contextualizeMarkEventSegue"){
            if let destinationVC = segue.destination as? MarkEventFormViewController {
                destinationVC.markEventDate = sender as! Date
                NSLog("sending this date: \( sender as! Date)")
            }
        }else{
            NSLog("Using unidentified segue: \(String(describing: segue.identifier))")
        }
    }
    
    // I think this gets called when a back button is pressed. maybe reload markeventcnt?
    @IBAction func unwindEmotionView(segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func gotoEvalEmotionSegue(_ sender: UIButton) {
        //TODO: if I add a map feature later I need to alter the sender into a dict
        performSegue(withIdentifier: "evalEmotionSegue", sender: self)
        NSLog("using evalEmotionSegue")
    }
    
    func fillMarkEvent(timeOfMark : Date){
        NSLog("using contextualizeMarkEventSegue with time: \(timeOfMark)")
         performSegue(withIdentifier: "contextualizeMarkEventSegue", sender: timeOfMark)
    }

    

    private func castHKUnitToDouble(theSample :HKQuantitySample, theUnit : HKUnit) -> Double{
        if(!theSample.quantity.is(compatibleWith: theUnit)){
            NSLog("measurement value type of %@ isn't compatible with %@" , theSample.quantityType.identifier, theUnit)
            return -1.0
        }else{
            return theSample.quantity.doubleValue(for: theUnit)
        }
    }
    
    func handleBioSamples(samples : [HKQuantitySample], startDate : Date, endDate : Date){
        var bioSamples = Array<BioSampleObj>()
        
        if(samples.count > 0){
            for sample in samples{
                var measurementValue = -1.0
                var type = "-1"
                switch sample.quantityType.identifier{
                case "HKQuantityTypeIdentifierHeartRate":
                    measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit.beatsPerMinute())
                    type = "HR"
                case "HKQuantityTypeIdentifierVO2Max":
                    measurementValue = castHKUnitToDouble(theSample : sample, theUnit: HKUnit(from: "ml/kg*min"))
                    type = "O2"
                default:
                    //TODO: find a better way to report this error
                    NSLog("Can't find a quantity type for: %@", sample.quantityType.identifier)
                }
                
                let sampleEndTime = sample.endDate
                let sampleStartTime = sample.startDate
                
                if(sampleEndTime > startDate && sampleEndTime < endDate){
                    bioSamples.append(BioSampleObj(
                        type: type,
                        startTime : sampleStartTime,
                        endTime : sampleEndTime,
                        measurement : measurementValue))
                }
            }
        }
        if(bioSamples.count == 0){
            NSLog("No samples found in query. Not sending anything to server")
        }else{
            self.httpManager.uploadBioSamples(bioSamples : bioSamples)
        }    }
}

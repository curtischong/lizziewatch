//
//  MainViewController.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.


import UIKit
import HealthKit


protocol mainProtocol {
    func updateLastSync(userInfo : [String : Any])
    func updateMarkEvent()
}

//TODO: find a way to show the shared folder and move the healthKitDataPoint to it
class MainViewController: UIViewController, UITableViewDelegate, mainProtocol{
    
    
    @IBOutlet weak var syncToPhoneStateLabel: UILabel!
    @IBOutlet weak var markEventCntPhone: UILabel!
    
    @IBOutlet weak var markEventTable: UITableView!
    @IBOutlet weak var dateLastSyncLabel: UILabel!
    
    @IBOutlet weak var uploadBioSamplesButton: UIButton!
    var syncToPhoneState = false
    private let dataSource = DataSource()
    
    
    //MARK: Properties
    
    let appContextFormatter = DateFormatter()
    let displayDateFormatter = DateFormatter()
    let settingsManager = SettingsManager()
    let httpManager = HttpManager()
    let hkManager = HKManager()
    let dataManager = DataManager()
    let watchNetworkManager = WatchNetworkManager()
    
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

        updateMarkEvent()
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
        //updateMarkEvent()
    }
    
    //MARK: Actions
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fillMarkEvent(timeOfMark : dataSource.markEvents[indexPath.row].timeOfMark)
    }
    
    func updateMarkEvent(){
        let markEvents = dataManager.getAllMarkEvents()
        dataSource.markEvents = markEvents
        markEventTable.dataSource = dataSource
        markEventTable.reloadData()
        
        if(markEvents.count == 0){
            // TODO: replace this button with something more useful
            //uploadBioSamplesButton.isHidden = false
            uploadBioSamplesButton.isHidden = true
            markEventTable.isHidden = true
        }else{
            uploadBioSamplesButton.isHidden = true
            markEventTable.isHidden = false
        }
    }
    
    @IBAction func syncWatchData(_ sender: Any) {
        watchNetworkManager.syncWatchData()
    }
    
    func updateLastSync(userInfo : [String : Any]){
        self.syncToPhoneStateLabel.text = "Synced"
        dateLastSyncLabel.text = userInfo["selectBeforeTime"] as? String
    }

    
    // MARK: - Navigation
        
    @IBAction func markEventButtonPress(_ sender: UIButton) {
        if(dataManager.insertMarkEvents(timeOfMarks : [Date()])){
            updateMarkEvent()
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

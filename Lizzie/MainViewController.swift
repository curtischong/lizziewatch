//
//  MainViewController.swift
//  
//
//  Created by Curtis Chong on 2018-12-26.


import UIKit
import HealthKit


protocol mainProtocol {
    func updateLastSync(userInfo : [String : Any])
    func reloadMarkEventTable()
}

//TODO: find a way to show the shared folder and move the healthKitDataPoint to it
@available(iOS 11.0, *)
class MainViewController: UIViewController, UITableViewDelegate, mainProtocol{
    
    
    @IBOutlet weak var syncToPhoneStateLabel: UILabel!
    @IBOutlet weak var uploadEventsBtn: UIButton!
    
    
    @IBOutlet weak var markEventTable: UITableView!
    @IBOutlet weak var dateLastSyncLabel: UILabel!
    
    @IBOutlet weak var uploadBioSamplesButton: UIButton!
    var syncToPhoneState = false
    private let dataSource = MarkEventTableDataSource()
    let generator = UIImpactFeedbackGenerator(style: .light)
    
    
    //MARK: Properties
    
    let appContextFormatter = DateFormatter()
    let displayDateFormatter = DateFormatter()
    let settingsManager = SettingsManager()
    let httpManager = HttpManager()
    let hkManager = HKManager()
    let dataManager = DataManager()
    let watchNetworkManager = WatchNetworkManager()
    let permissionsManager = PermissionsManager()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func uploadToServer(){
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
            NSLog("last synced time: \(startDate)")
        }
        
        hkManager.queryBioSamples(startDate : startDate, endDate : endDate) { samples, error in
            guard let samples = samples else { return }
            
            let bioSamples = self.hkManager.handleBioSamples(samples : samples, startDate : startDate, endDate : endDate)
            if(bioSamples.count > 0){
                NSLog("Sending biopoints to server")
                self.httpManager.uploadBioSamples(bioSamples : bioSamples)
            }
        }
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        appContextFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        markEventTable.delegate = self

        // update the number of items not synced:

        reloadMarkEventTable()
        // NSLog("Main View Loaded")
        
        if(settingsManager.dateLastSyncedWithWatch != nil){
            dateLastSyncLabel.text = displayDateFormatter.string(from: settingsManager.dateLastSyncedWithWatch!)
        }
        permissionsManager.authenticateForHealthstoreData(successFunc: uploadToServer())
        
        // Used only in testing
        //dataManager.dropAllRows()
        //updateMarkEvent()
    }
    
    //MARK: Actions
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fillMarkEvent(markEventObj: dataSource.markEvents[indexPath.row])
    }
    
    func reloadMarkEventTable(){
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
        generator.impactOccurred()
        self.syncToPhoneStateLabel.text = "Synced"
        dateLastSyncLabel.text = userInfo["selectBeforeTime"] as? String
    }

    
    // MARK: - Navigation
        
    @IBAction func markEventButtonPress(_ sender: UIButton) {
        generator.impactOccurred()
        let newMarkEvent = MarkEventObj(markTime: Date())
        if(dataManager.insertMarkEvent(markEvent: newMarkEvent)){
            reloadMarkEventTable()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        generator.impactOccurred()
        if segue.identifier == "evalEmotionSegue"{ // no params to pass as of this version
            if segue.destination is EvalEmotionViewController {
                
            }
        }else if(segue.identifier == "contextualizeMarkEventSegue"){
            if let destinationVC = segue.destination as? MarkEventFormViewController {
                destinationVC.markEventObj = (sender as! MarkEventObj)
                print("\(destinationVC.markEventObj.emotionsFelt)")
                print("\(destinationVC.markEventObj.name)")
                NSLog("sending MarkEventObj: \(sender as! MarkEventObj)")
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
    
    func fillMarkEvent(markEventObj : MarkEventObj){
        performSegue(withIdentifier: "contextualizeMarkEventSegue", sender: markEventObj)
    }
}

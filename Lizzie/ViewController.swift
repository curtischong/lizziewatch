//
//  ViewController.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
// TODO: Add a button that switches between minutes and seconds... or have it automatically switch
// TODO: improve the quering thing. Since we at most query for times 5 min on each side,
// We can query for the 10 minute interval then crop. we don't need to requery each time
// TODO: we should add code so you can't move the left sider further that where the right slider ends

import UIKit
import Charts
import Alamofire
import SwiftyJSON
import WatchConnectivity
import CoreData


struct chartPoint{
    let endTime : Date
    let measurement : Double
}

extension Date {
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}


class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate{

    //MARK: Properties
    //@IBOutlet weak var eventTextLabel: UILabel!
    @IBOutlet weak var eventTextField: UITextField!
    
    @IBOutlet weak var eventDurationTextLabel: UILabel!
    @IBOutlet weak var eventDurationSlider: UISlider!
    
    @IBOutlet weak var heartrateChart: LineChartView!
    @IBOutlet weak var commentBoxTextView: UITextView!
    @IBOutlet weak var selectPointsButton: UIButton!
    @IBOutlet weak var timeStartSlider: UISlider!
    @IBOutlet weak var timeEndSlider: UISlider!
    @IBOutlet weak var isReactionSwitch: UISwitch!
    
    let displayDateFormatter = DateFormatter()
    
    var selectedEmotions = Array(repeating: false, count: 8)
    var markEventDate: Date = Date()
    var bioPoints : [chartPoint]?
    var selectedPoints = false
    var isReaction = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // sets the carrier, time, and battery to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Setting things up")
        
        // Colors:
        commentBoxTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        commentBoxTextView.layer.borderWidth = 1.0
        commentBoxTextView.layer.cornerRadius = 5
        
        heartrateChart.legend.textColor = UIColor.white
        heartrateChart.xAxis.labelTextColor = UIColor.white
        heartrateChart.leftAxis.labelTextColor = UIColor.white
        heartrateChart!.rightAxis.enabled = false
        heartrateChart.data?.setValueTextColor(UIColor.white)
        
        
        
        
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        
        // IOS Setup
        eventTextField.delegate = self
        eventTextField.placeholder = self.displayDateFormatter.string(from: markEventDate)

        // Textview
        commentBoxTextView.delegate = self
        commentBoxTextView.text = "Comments"
        commentBoxTextView.textColor = UIColor.lightGray
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        eventDurationTextLabel.text = "1.0 min"
        eventDurationSlider.setValue(0.2, animated: true)
        
        timeStartSlider.isEnabled = false
        timeEndSlider.isEnabled = false
        timeStartSlider.setValue(0.0, animated: true)
        timeEndSlider.setValue(1.0, animated: true)
        
        view.bringSubviewToFront(isReactionSwitch)
        NSLog("Finished Setting things up")
        updateGraph()
    }
    
    // textview functions
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if commentBoxTextView.textColor == UIColor.lightGray {
            commentBoxTextView.text = nil
            commentBoxTextView.textColor = UIColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if commentBoxTextView.text.isEmpty {
            commentBoxTextView.text = "Comments?"
            commentBoxTextView.textColor = UIColor.lightGray
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSLog("Received Memory Warning. I need to quickly save everything")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //eventTextLabel.text = textField.text
    }
    
    func updateGraph(){
        bioPoints = queryBioSamples()
        var lineChartEntry = [ChartDataEntry]()

        var lowestAbs = 9999.0
        var lowestIdx = 0
        for i in 0...(bioPoints!.count - 1){
            //NSLog("Cur Time: \(Double(bioPoints![i].endTime.seconds(from : markEventDate)))")
            let difference = Double(bioPoints![i].endTime.seconds(from : markEventDate))
            //NSLog("\(difference)")
            if(abs(difference) < lowestAbs){
                lowestIdx = i
                lowestAbs = abs(difference)
            }
            let value = ChartDataEntry(x: difference, y: bioPoints![i].measurement)
            lineChartEntry.append(value)
        }
        NSLog("The closest datapoint to the timeOfMark is \(lowestAbs) seconds away. It is the \(lowestIdx)th idx")
        
        let line = LineChartDataSet(values: lineChartEntry, label: "Heartrate")
        line.colors = [UIColor.red]
        line.drawCirclesEnabled = false
        line.drawValuesEnabled = false
        line.setDrawHighlightIndicators(false)
        
        let data = LineChartData()
        data.addDataSet(line)
        heartrateChart.data = data
        heartrateChart.highlightValue(x: 0.0, y: bioPoints![lowestIdx].measurement, dataSetIndex: 0, callDelegate: true)
        //heartrateChart.chartDescription?.text = "Heartrate"
    }
    
    func queryBioSamples() -> [chartPoint]{
        
        let numMinutesGap = eventDurationSlider.value * 5.0
        let endTime = markEventDate.addingTimeInterval(TimeInterval(numMinutesGap * 60.0))
        let startTime = markEventDate.addingTimeInterval(TimeInterval(-numMinutesGap * 60.0))
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BioSamplePhone")
        //"endTime => %@ AND endTime <= %@ AND (dataPointName == HR OR dataPointName == X)"
        //TODO: add breathing?
        request.predicate = NSPredicate(format: "dataPointName == %@ AND startTime >= %@ AND endTime <= %@", "HR", startTime as NSDate, endTime as NSDate)
        
        do{
            let result = try context.fetch(request)
            let numItems = result.count
            NSLog("Found \(numItems) items for the Chart")
            if(numItems > 0 ){
                var HRPoints = Array<chartPoint>()
                
                for sample in result as! [NSManagedObject] {
                    let curChartPoint = chartPoint(
                        endTime : sample.value(forKey: "endTime") as! Date,
                        measurement : sample.value(forKey: "measurement") as! Double
                    )
                    HRPoints.append(curChartPoint)
                    //NSLog(sample.value(forKey: "dataPointName") as! String)
                }
                HRPoints = HRPoints.sorted{ $1.endTime > $0.endTime }
                return HRPoints
            }
        }catch let error{
            NSLog("Couldn't read BioSamples between the times: \(startTime) and \(endTime) with error: \(error)")
        }
        return [chartPoint(endTime : Date(), measurement : -1)]
    }
    
    // Mark: Actions
    @IBAction func selectPointsClicked(_ sender: UIButton) {
        sender.isEnabled = false
        if(!isReaction){
            eventDurationSlider.isEnabled = false
        }else{
            eventDurationSlider.minimumTrackTintColor = UIColor.lightGray
            eventDurationSlider.isEnabled = true
        }
        timeStartSlider.isEnabled = true
        timeEndSlider.isEnabled = true
        selectedPoints = true
    }
    @IBAction func eventDurationSliderChanged(_ sender: UISlider) {
        if(selectedPoints){
            
        }else{
            eventDurationTextLabel.text = String(format: "%.2f", eventDurationSlider.value * 5.0) + " min"
            updateGraph()
        }
    }
    
    @IBAction func goBackToOneButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
    }
    @IBAction func isReactionSwitch(_ sender: Any) {
        if(isReaction){
            isReaction = false
        }else{
            isReaction = true
        }
        if(selectedPoints){
            if(isReaction){
                eventDurationSlider.isEnabled = true
            }else{
                eventDurationSlider.isEnabled = false
            }
        }
    }
    
    
    
    /*
     let sliderPos = normalEvalSlider.value
     let sliderVal = round(sliderPos*5)/5
     let realVal = Int(round(sliderPos*5))
     normalEvalSliderLabel.text = "\(realVal)"
     sender.setValue(sliderVal, animated: true)
     */
    
    @IBAction func timeStartSliderMoved(_ sender: UISlider) {
        let timeStartSliderPos = timeStartSlider.value
        let timeEndSliderPos = timeEndSlider.value
        if(timeStartSliderPos > timeEndSliderPos){
            sender.setValue(timeEndSliderPos, animated: true)
        }
    }
    
    @IBAction func timeEndSliderMoved(_ sender: UISlider) {
        let timeStartSliderPos = timeStartSlider.value
        let timeEndSliderPos = timeEndSlider.value
        if(timeEndSliderPos < timeStartSliderPos){
            sender.setValue(timeStartSliderPos, animated: true)
        }
    }
    
    
    
    

    @IBAction func sendBioSnapshot(_ sender: Any) {
        
        let parameters: Parameters = [
            "timestart": "1233",
            "timeend":"123",
            "heartrate": "232323"
        ]
        //let config = readConfig()
        //print(config["ip"])
        
        
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
}

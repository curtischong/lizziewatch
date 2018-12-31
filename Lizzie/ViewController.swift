//
//  ViewController.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
// TODO: Add a button that switches between minutes and seconds... or have it automatically switch
// TODO: improve the quering thing. Since we at most query for times 5 min on each side,
// We can query for the 10 minute interval then crop. we don't need to requery each time
// TODO: when we upload the markevents we also want to upload when we made the mark event. (so we can see it's relation to the crop

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
    
    var markEventDate: Date = Date()
    
    private let displayDateFormatter = DateFormatter()
    private var selectedEmotions = Array(repeating: false, count: 8)
    private var bioPoints = [String : [chartPoint]]()
    private var selectedPoints = false
    private var isReaction = false
    private var activeTypingField = ""
    private var lineChartEntry = [String : [ChartDataEntry]]()
    private var highlight1 : Highlight?
    private var highlight2 : Highlight?
    private var highlight3 : Highlight?
    // I need to refactor this and use a map

    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // sets the carrier, time, and battery to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Setting things up")
        

        bioPoints = queryBioSamples()
        // Colors:
        commentBoxTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        commentBoxTextView.layer.borderWidth = 1.0
        commentBoxTextView.layer.cornerRadius = 5
        
        heartrateChart.legend.textColor = UIColor.white
        heartrateChart.xAxis.labelTextColor = UIColor.white
        heartrateChart.leftAxis.labelTextColor = UIColor.white
        heartrateChart!.rightAxis.enabled = false
        heartrateChart.data?.setValueTextColor(UIColor.white)
        heartrateChart.highlightPerTapEnabled = false
        heartrateChart.highlightPerDragEnabled = false
        heartrateChart.pinchZoomEnabled = false
        //heartrateChart.isDragEnabled(false)
        //heartrateChart.setHighlightPerDragEnabled(false)
        //heartrateChart!.setHighlightPerTapEnabled(false)
        
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTypingField = "eventTextField"
    }
    
    func textViewDidBeginEditing(textField: UITextView) {
        activeTypingField = "commentBoxTextView"
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if(commentBoxTextView.isFirstResponder){
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
            activeTypingField = ""
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
        //ineChartEntry["HR"] = []()
        var tempArr : [ChartDataEntry] = []
        for i in 0...(bioPoints["HR"]!.count - 1){
            //NSLog("Cur Time: \(Double(bioPoints!["HR"]![i].endTime.seconds(from : markEventDate)))")
            let difference = Double(bioPoints["HR"]![i].endTime.seconds(from : markEventDate))
            if(abs(difference) < Double(eventDurationSlider.value) * 5.0 * 60.0){
                let value = ChartDataEntry(x: difference, y: bioPoints["HR"]![i].measurement)
                tempArr.append(value)
            }
        }
        
        lineChartEntry["HR"] = tempArr
        
        let line = LineChartDataSet(values: lineChartEntry["HR"], label: "Heartrate")
        line.colors = [UIColor.red]
        line.drawCirclesEnabled = false
        line.drawValuesEnabled = false
        //line.setDrawHighlightIndicators(false)
        
        line.highlightEnabled = true
        line.setDrawHighlightIndicators(true)
        line.drawHorizontalHighlightIndicatorEnabled = false

        line.highlightColor = UIColor.white
        //line.highlightLineWidth = 1
        
        //Highlight(float x, int dataSetIndex) { ... }
        
        let data = LineChartData()
        data.addDataSet(line)
        heartrateChart.data = data
        //heartrateChart.highlightValue(x: 0.0, y: bioPoints![lowestIdx].measurement, dataSetIndex: 0, callDelegate: true)
        //heartrateChart.chartDescription?.text = "Heartrate"
    }
    
    func queryBioSamples() -> [String : [chartPoint]]{
        
        let numMinutesGap = 5.0
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
                    //NSLog("\(sample.value(forKey: "endTime"))")
                }
                HRPoints = HRPoints.sorted{ $1.endTime > $0.endTime }
                return ["HR" : HRPoints]
            }
        }catch let error{
            NSLog("Couldn't read BioSamples between the times: \(startTime) and \(endTime) with error: \(error)")
        }
        return ["HR" : [chartPoint(endTime : Date(), measurement : -1)]]
    }
    
    // Mark: Actions
    @IBAction func selectPointsClicked(_ sender: UIButton) {
        sender.isEnabled = false
        if(isReaction){
            eventDurationSlider.isEnabled = false
        }else{
            eventDurationSlider.minimumTrackTintColor = UIColor.lightGray
            eventDurationSlider.isEnabled = true
        }
        timeStartSlider.isEnabled = true
        timeEndSlider.isEnabled = true
        selectedPoints = true
    }
    
    func getAllHighlights() -> [Highlight]{
        var allHighlights = [Highlight]()
        if(highlight1 != nil){
            allHighlights.append(highlight1!)
        }
        if(highlight2 != nil){
            allHighlights.append(highlight2!)
        }
        if(highlight3 != nil){
            allHighlights.append(highlight3!)
        }
        return allHighlights
    }
    
    func getNewXForHightlight3() -> Int{
        let sliderPos = eventDurationSlider.value
        let numEntries = lineChartEntry["HR"]!.count
        var closestIdx = Int((Double(sliderPos) * Double(numEntries)))
        if(closestIdx == numEntries){
            closestIdx = closestIdx - 1
        }
        return closestIdx
    }
    
    @IBAction func eventDurationSliderChanged(_ sender: UISlider) {
        if(selectedPoints){
            let closestIdx = getNewXForHightlight3()
            highlight3 = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
            heartrateChart.highlightValues(getAllHighlights())
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
            let closestIdx = getNewXForHightlight3()
            highlight3 = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
            heartrateChart.highlightValues(getAllHighlights())
            isReaction = false
        }else{
            highlight3 = nil
            heartrateChart.highlightValues(getAllHighlights())
            isReaction = true
        }
        if(selectedPoints){
            if(isReaction){
                eventDurationSlider.isEnabled = false
            }else{
                eventDurationSlider.isEnabled = true
            }
        }
    }
    
    
    @IBAction func timeStartSliderMoved(_ sender: UISlider) {
        let timeStartSliderPos = timeStartSlider.value
        let timeEndSliderPos = timeEndSlider.value
        if(timeStartSliderPos > timeEndSliderPos){
            sender.setValue(timeEndSliderPos, animated: true)
        }else{
            
            let numEntries = lineChartEntry["HR"]!.count
            var closestIdx = Int((Double(timeStartSliderPos) * Double(numEntries)))
            if(closestIdx == numEntries){
                closestIdx = closestIdx - 1
            }
            
            //NSLog("Index of the point closest to timeStartSlider: \(closestIdx)")
            let newX = Double(lineChartEntry["HR"]![closestIdx].x)
            if(highlight2 != nil && newX == highlight2!.x){
                heartrateChart.highlightValues(getAllHighlights())
            }else{
                highlight1 = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
                heartrateChart.highlightValues(getAllHighlights())
            }
        }
    }
    
    @IBAction func timeEndSliderMoved(_ sender: UISlider) {
        let timeStartSliderPos = timeStartSlider.value
        let timeEndSliderPos = timeEndSlider.value
        if(timeEndSliderPos < timeStartSliderPos){
            sender.setValue(timeStartSliderPos, animated: true)
        }else{
            
            let numEntries = lineChartEntry["HR"]!.count
            var closestIdx = Int((Double(timeEndSliderPos) * Double(numEntries)))
            if(closestIdx == numEntries){
                closestIdx = closestIdx - 1
            }
            //NSLog("Index of the point closest to timeEndSlider: \(closestIdx)")
            let newX = Double(lineChartEntry["HR"]![closestIdx].x)
            if(highlight1 != nil && newX == highlight1!.x){
                heartrateChart.highlightValues(getAllHighlights())
            }else{
                highlight2 = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
                heartrateChart.highlightValues(getAllHighlights())
            }
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

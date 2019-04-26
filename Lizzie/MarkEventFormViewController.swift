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
// TODO: add the fill color for the bottom of the chart slider: datset.fill = ChartFill.fill(withColor: color.withAlphaComponent(0.8))
//NOTE: when we send the dates to the server, the range between the crops is INCLUSIVE.


// Documentation
// highlight 1 is the left crop line
// highlight 2 is the right crop line
// highlight 3 is the middle crop line

import UIKit
import Charts
import HealthKit

//TODO: move this elsewhere.
// I'm really press on time rn
extension HKUnit {
    
    static func beatsPerMinute() -> HKUnit {
        return HKUnit.count().unitDivided(by: HKUnit.minute())
    }
    
}

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


class MarkEventFormViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate{

    //MARK: Properties
    //@IBOutlet weak var eventTextLabel: UILabel!
    @IBOutlet var eventTextField: UITextField!
    
    @IBOutlet var eventDurationTextLabel: UILabel!
    @IBOutlet var eventDurationSlider: UISlider!
    
    @IBOutlet var heartrateChart: LineChartView!
    @IBOutlet var commentBoxTextView: UITextView!
    @IBOutlet var selectPointsButton: UIButton!
    @IBOutlet var timeStartSlider: UISlider!
    @IBOutlet var timeEndSlider: UISlider!
    @IBOutlet var isReactionSwitch: UISwitch!
    @IBOutlet var uploadButton: UIButton!
    
    @IBOutlet var evaluateEmotionBar: EmotionSelectionElement!
    var markEventDate: Date = Date()
    
    private let displayDateFormatter = DateFormatter()
    private var selectedEmotions = Array(repeating: false, count: 8)
    private var bioPoints = [String : [chartPoint]]()
    private var selectedPoints = false
    private var isReaction = false
    private var activeTypingField = ""
    private var lineChartEntry = [String : [ChartDataEntry]]()
    //private var lineChartEntryDates = [String : [Date]]()
    private var highlight1 : Highlight?
    private var highlight2 : Highlight?
    private var highlight3 : Highlight?
    private let typesOfBiometrics = ["HR"]


    let generator = UIImpactFeedbackGenerator(style: .light)
    private let commentBoxPlaceholder = "Comments"
    let httpManager = HttpManager()
    let dataManager = DataManager()
    let hkManager = HKManager()
    // I need to refactor this and use a map

    
    // sets the carrier, time, and battery to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*// setting it to negative 100 weeks so we notice if something's wrong
        highlight1Date = Date().addingTimeInterval(-700 * 24 * 60 * 60)
        highlight2Date = Date().addingTimeInterval(-700 * 24 * 60 * 60)
        highlight3Date = Date().addingTimeInterval(-700 * 24 * 60 * 60)*/
        
        uploadButton.setTitleColor(UIColor.lightGray, for: .normal)
        uploadButton.isEnabled = false
        //NSLog("Setting things up")
        
        queryBioSamples()
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
        heartrateChart.drawBordersEnabled = true
        heartrateChart.minOffset = 0
        
        //heartrateChart.isDragEnabled(false)
        //heartrateChart.setHighlightPerDragEnabled(false)
        //heartrateChart!.setHighlightPerTapEnabled(false)
        
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        
        // IOS Setup
        eventTextField.delegate = self
        eventTextField.placeholder = self.displayDateFormatter.string(from: markEventDate)
        
        // Textview
        commentBoxTextView.delegate = self
        commentBoxTextView.text = commentBoxPlaceholder
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
        generator.impactOccurred()
        if commentBoxTextView.textColor == UIColor.lightGray {
            commentBoxTextView.text = nil
            commentBoxTextView.textColor = UIColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if commentBoxTextView.text.isEmpty {
            commentBoxTextView.text = commentBoxPlaceholder
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
        var tempArr1 : [ChartDataEntry] = []
        //var tempArr2 : [Date] = []
        
        if let hrPoints = bioPoints["HR"] {
            for (index, _) in bioPoints.enumerated() {
                //NSLog("Cur Time: \(Double(bioPoints!["HR"]![i].endTime.seconds(from : markEventDate)))")
                let difference = Double(hrPoints[index].endTime.seconds(from : markEventDate))
                if(abs(difference) < Double(eventDurationSlider.value) * 5.0 * 60.0){
                    let value = ChartDataEntry(x: difference, y: hrPoints[index].measurement)
                    tempArr1.append(value)
                    //tempArr2.append(bioPoints["HR"]![i].endTime)
                }
            }
        }
        
        lineChartEntry["HR"] = tempArr1
        //lineChartEntryDates["HR"] = tempArr2
        
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
    
    
    
    
    
    private func castHKUnitToDouble(theSample :HKQuantitySample, theUnit : HKUnit) -> Double{
        /*if(!theSample.quantity.is(compatibleWith: theUnit)){
         NSLog("measurement value type of %@ isn't compatible with %@" , theSample.quantityType.identifier, theUnit)
         return -1.0
         }else{*/
        return theSample.quantity.doubleValue(for: theUnit)
        //}
    }
    
    
    
    
    func queryBioSamples(){
        
        // We are selecting all points in the last 60 minutes because the query checks for points that falls
        // within the start and end times of the query. Since we are only displaying the endtimes of the points,
        // we need to select more points because some points can start before the starttime but have an
        // end time that ends after the starttime in the query
        
        let numMinutesGap = 5.0
        let endDate = markEventDate.addingTimeInterval(TimeInterval(numMinutesGap * 60.0 * 60))
        let startDate = markEventDate.addingTimeInterval(TimeInterval(-numMinutesGap * 60.0 * 60))
        
        
        hkManager.queryBioSamples(startDate : startDate, endDate : endDate, descending : true) { samples, error in
            guard let samples = samples else { return }
            
            let bioSamples = self.hkManager.handleBioSamples(samples : samples, startDate : startDate, endDate : endDate)
            
            var HRPoints = Array<chartPoint>()
            if(bioSamples.count == 0){
                HRPoints.append(chartPoint(endTime : Date(), measurement : -1))
            }else{
                for sample in bioSamples{
                    let sampleEndTime = sample.endTime
                    let sampleMeasurement = sample.measurement
                    
                    if(sampleEndTime > startDate && sampleEndTime < endDate){
                        let curChartPoint = chartPoint(
                            endTime : sampleEndTime,
                            measurement : sampleMeasurement
                        )
                        HRPoints.append(curChartPoint)
                    }
                }
                NSLog("\(HRPoints.count)")
            }
            self.bioPoints = ["HR" : HRPoints]
            
            DispatchQueue.main.async {
                self.updateGraph()
            }
        }
    }
    
    private func checkIfCanUpload(){
        if(eventDurationSlider.value > timeStartSlider.value && eventDurationSlider.value < timeEndSlider.value){
            uploadButton.isEnabled = true
            uploadButton.setTitleColor(UIColor.cyan, for: .normal)
        }else{
            uploadButton.isEnabled = false
            uploadButton.setTitleColor(UIColor.lightGray, for: .normal)
        }
    }
    
    
    // Mark: Actions
    @IBAction func selectPointsClicked(_ sender: UIButton) {
        // since heartrate is the most frequent datapoint we can safely assume that if
        // there are no heartrate samples, then there are no other samples
        
        if(bioPoints["HR"]!.count > 0){
            sender.isEnabled = false
            uploadButton.isEnabled = true
            if(isReaction){
                
                eventDurationSlider.isEnabled = false
            }else{
                
                let closestIdx = getNewXForHightlight3()
                highlight3 = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
                heartrateChart.highlightValues(getAllHighlights())
                
                eventDurationSlider.minimumTrackTintColor = UIColor.lightGray
                eventDurationSlider.isEnabled = true
            }
            timeStartSlider.isEnabled = true
            timeEndSlider.isEnabled = true
            selectedPoints = true
        }else{
            NSLog("No Heartrate data! Can't select points")
        }
    }
    
    // The sole purpose of the lastHighlight is to see if the highlights moved to see if we need to vibrate
    var lastHighlight1 : Highlight? = nil
    var lastHighlight2 : Highlight? = nil
    var lastHighlight3 : Highlight? = nil
    
    func getAllHighlights() -> [Highlight]{
        var allHighlights = [Highlight]()
        
        if(highlight1 != lastHighlight1 || highlight2 != lastHighlight2 || highlight3 != lastHighlight3){
            generator.impactOccurred()
        }
        
        if(highlight1 != nil){
            lastHighlight1 = highlight1!
            allHighlights.append(highlight1!)
        }
        if(highlight2 != nil){
            lastHighlight2 = highlight2!
            allHighlights.append(highlight2!)
        }
        if(highlight3 != nil){
            lastHighlight3 = highlight3!
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
            if(!isReaction){
                checkIfCanUpload()
            }
        }else{
            eventDurationTextLabel.text = String(format: "%.2f", eventDurationSlider.value * 5.0) + " min"
            updateGraph()
        }
    }
    
    @IBAction func goBackToOneButtonTapped(_ sender: Any) {
        generator.impactOccurred()
        performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
    }
    @IBAction func isReactionSwitch(_ sender: Any) {
        if(isReaction){
            let closestIdx = getNewXForHightlight3()
            highlight3 = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
            heartrateChart.highlightValues(getAllHighlights())
            checkIfCanUpload()
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
            
            if(!isReaction){
                checkIfCanUpload()
            }
            
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
            
            if(!isReaction){
                checkIfCanUpload()
            }
            
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("Intercepted Segue")
        if segue.identifier == "unwindSegue2ToMainViewController"{ // no params to pass as of this version
            if let destinationVC = segue.destination as? MainViewController {
                destinationVC.updateMarkEvent()
                //NSLog("")
            }
        }else{
            NSLog("Using unidentified segue: \(String(describing: segue.identifier))")
        }
    }
    
    
    
    @IBAction func deleteEventPressed(_ sender: UIButton) {
        generator.impactOccurred()
        deleteCurrentMarkEvent()
    }
    
    func deleteCurrentMarkEvent(){
        if(dataManager.deleteMarkEvent(timeOfMark: markEventDate)){
            performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
        }
    }
    
    func json(from object: [Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }

    @IBAction func sendBioSnapshot(_ sender: Any) {
        
        generator.impactOccurred()
        // This says: find the x value of the highlight (which is conveniently the number of seconds away from the timeOfMark)
        // Then add that time from the time of the timeOfMark
        let highlight1Date = markEventDate.addingTimeInterval(TimeInterval(highlight1!.x))
        let highlight2Date = markEventDate.addingTimeInterval(TimeInterval(highlight2!.x))
        var highlight3Date = Date()
        
        
        
        var timeOfEvent = highlight3Date
        if(isReaction){
            timeOfEvent = highlight1Date
        }else{
            highlight3Date = markEventDate.addingTimeInterval(TimeInterval(highlight3!.x))
        }
        
        var commentsToSend = commentBoxTextView.text
        if(commentsToSend == commentBoxPlaceholder){
            commentsToSend = ""
        }
        
        print("\(json(from : evaluateEmotionBar.getButtonStates())!)")
        
        let buttonStates : [Int] = evaluateEmotionBar.getButtonStates()
        
        
        let markEventObj = MarkEventObj(timeOfMark: markEventDate,
                                        isReaction: isReaction,
                                        anticipationStart: highlight1Date,
                                        timeOfEvent: timeOfEvent,
                                        reactionEnd: highlight2Date,
                                        emotionsFelt: buttonStates,
                                        comments: commentsToSend!,
                                        typeBiometricsViewed: [0])
        httpManager.uploadMarkEvent(markEventObj: markEventObj)
        self.deleteCurrentMarkEvent()
        self.performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
        
    }
}

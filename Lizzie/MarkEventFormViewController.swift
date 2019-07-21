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


@available(iOS 11.0, *)
class MarkEventFormViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, emotionSelectionElementDelegate{

    //MARK: Properties
    //@IBOutlet weak var eventTextLabel: UILabel!
    @IBOutlet var eventTextField: UITextField!
    
    @IBOutlet var eventDurationTextLabel: UILabel!
    @IBOutlet var mcrop: UISlider!
    
    @IBOutlet var heartrateChart: LineChartView!
    @IBOutlet var commentBoxTextView: UITextView!
    @IBOutlet var selectPointsButton: UIButton!
    @IBOutlet var lcrop: UISlider!
    @IBOutlet var rcrop: UISlider!
    @IBOutlet var anticipateSwitch: UISwitch!
    @IBOutlet var uploadButton: UIButton!
    
    @IBOutlet var evaluateEmotionBar: EmotionSelectionElement!
    
    private let displayDateFormatter = DateFormatter()
    private var selectedEmotions = Array(repeating: false, count: 8)
    private var bioPoints = [String : [chartPoint]]()
    private var activeTypingField = ""
    private var lineChartEntry = [String : [ChartDataEntry]]()
    //private var lineChartEntryDates = [String : [Date]]()
    private var lhighlight : Highlight?
    private var rhighlight : Highlight?
    private var mhighlight : Highlight?
    private let typesOfBiometrics = ["HR"]
    
    let generator = UIImpactFeedbackGenerator(style: .light)
    private let commentBoxPlaceholder = "Comments"
    let httpManager = HttpManager()
    let dataManager = DataManager()
    let hkManager = HKManager()
    var toolbar : UIToolbar!
    
    let numMinutesGap = 5.0
    
    var markEventObj : MarkEventObj!
    
    // sets the carrier, time, and battery to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // TODO: I need to store 2 values: the time look back duration and the third highlight location
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // uploadButton
        
        uploadButton.setTitleColor(UIColor.lightGray, for: .normal)
        uploadButton.isEnabled = false
        
        // Comment Box
        
        commentBoxTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        commentBoxTextView.layer.borderWidth = 1.0
        commentBoxTextView.layer.cornerRadius = 5
        
        // Chart
        
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
        
        
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //init toolbar
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.commentBoxTextView.inputAccessoryView = toolbar
        
        // variable Setup
        queryBioSamples() // also plots graph!
        
        // Title box
    
        commentBoxTextView.delegate = self
        evaluateEmotionBar.delegate = self
        eventTextField.delegate = self
        
        eventTextField.placeholder = self.displayDateFormatter.string(from: markEventObj.markTime)
        eventTextField.text = markEventObj.name
        
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        
        // Textview
        if(markEventObj.comment == ""){
            commentBoxTextView.text = commentBoxPlaceholder
            commentBoxTextView.textColor = UIColor.lightGray
        }else{
            commentBoxTextView.text = markEventObj.comment
            commentBoxTextView.textColor = UIColor.white
        }
        
        selectPointsButton.setTitleColor(.gray, for: .disabled)
        if(markEventObj.pointsSelected){
            selectPointsButton.isEnabled = false
            if(markEventObj.anticipate){
                anticipateSwitch.isOn = true
                mcrop.isEnabled = true
            }else{
                anticipateSwitch.isOn = false
                mcrop.isEnabled = false
            }
            lcrop.isEnabled = true
            rcrop.isEnabled = true
        }else{
            selectPointsButton.isEnabled = true
            anticipateSwitch.isEnabled = false
            anticipateSwitch.isOn = true
            lcrop.isEnabled = false
            rcrop.isEnabled = false
        }
        
        lcrop.setValue(Float(markEventObj.lcrop), animated: true)
        rcrop.setValue(Float(markEventObj.rcrop), animated: true)
        
        if(markEventObj.pointsSelected){
            mcrop.setValue(Float(markEventObj.mcrop), animated: true)
        }else{
            mcrop.setValue(Float(markEventObj.selectionRange), animated: true)
        }
        
        
        evaluateEmotionBar.setButtonStates(buttonStates: markEventObj.emotionsFelt)
        setupEventDurationString()
        view.bringSubviewToFront(anticipateSwitch)
    }
    
    // textview functions
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(eventTextField.isFirstResponder){
            /*if(text == "\n") {
                textView.resignFirstResponder()
                return false
            }*/
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        generator.impactOccurred()
        activeTypingField = "commentBoxTextView"
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
        generator.impactOccurred()
        activeTypingField = "eventTextField"
    }
    
    // Keyboard Functions
    
    @objc func doneButtonAction() {
        generator.impactOccurred()
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if(commentBoxTextView.isFirstResponder){
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= (keyboardSize.height + 30) // 30 is the size of the toolbar
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
            activeTypingField = ""
        }
        if(eventTextField.isFirstResponder){
            markEventObj.name = eventTextField.text!
            dataManager.updateMarkEvent(markEvent: markEventObj)
        }else if(commentBoxTextView.isFirstResponder){
            markEventObj.comment = commentBoxTextView.text!
            dataManager.updateMarkEvent(markEvent: markEventObj)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSLog("Received Memory Warning. I need to quickly save everything")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        generator.impactOccurred()
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //eventTextLabel.text = textField.text
    }
    
    func updateEmotionsFelt(emotionsFelt : [String : Int]) -> (Void){
        markEventObj.emotionsFelt = emotionsFelt
        NSLog("\(emotionsFelt)")
        dataManager.updateMarkEvent(markEvent: markEventObj)
    }
    
    func pointsNotInOrder(points: [ChartDataEntry])  -> Bool {
        var last_val = -9999.0
        for point in points {
            if point.x < last_val {
                return true
            }
            last_val = point.x
        }
        return false
    }
    
    // TODO: impliment this
    func checkFormComplete(){
        
    }
    
    func updateGraph(){
        var tempArr1 : [ChartDataEntry] = []
        
        if let hrPoints = self.bioPoints["HR"] {
            for point in hrPoints {
                //NSLog("Cur Time: \(Double(bioPoints!["HR"]![i].endTime.seconds(from : markEventObj.markTime)))")
                let difference = Double(point.endTime.seconds(from : markEventObj.markTime))
                if(abs(difference) < Double(markEventObj.selectionRange) * numMinutesGap * 60.0){
                    let value = ChartDataEntry(x: difference, y: point.measurement)
                    tempArr1.append(value)
                }
            }
        }
        if pointsNotInOrder(points: tempArr1){
            fatalError("points on graph need to be chronologically ordered!")
        }
        
        lineChartEntry["HR"] = tempArr1
        
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
        
        let data = LineChartData()
        data.addDataSet(line)
        heartrateChart.data = data
    }
    
    
    func queryBioSamples(){
        
        // We are selecting all points in the last 60 minutes because the query checks for points that falls
        // within the start and end times of the query. Since we are only displaying the endtimes of the points,
        // we need to select more points because some points can start before the starttime but have an
        // end time that ends after the starttime in the query
        
        let endDate = markEventObj.markTime.addingTimeInterval(TimeInterval(numMinutesGap * 60.0))
        let startDate = markEventObj.markTime.addingTimeInterval(TimeInterval(-numMinutesGap * 60.0))
        
        
        hkManager.queryBioSamples(startDate : startDate, endDate : endDate, descending : false) { samples, error in
            guard let samples = samples else {return}
            
            let bioSamples = self.hkManager.handleBioSamples(samples : samples, startDate : startDate, endDate : endDate)
            
            var HRPoints = Array<chartPoint>()
            if(bioSamples.count == 0){
                // I think this is to stop the graph from dying
                HRPoints.append(chartPoint(endTime : Date(), measurement : -1))
            }else{
                for sample in bioSamples{
                    let sampleEndTime = sample.endTime
                    let sampleMeasurement = sample.measurement
                    if(sampleEndTime > startDate){
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
                if(self.markEventObj.pointsSelected && self.bioPoints["HR"]!.count > 1){
                    self.setlSlider()
                    self.setmSlider()
                    self.setrSlider()
                }
            }
        }
    }
    
    // A function called when we are anticipating an event
    private func checkIfCanUpload(){
        if(!markEventObj.anticipate){
            fatalError("You can only call checkIfCanUpload if you are anticipating!")
        }
        if(mhighlight != nil && lhighlight != nil && rhighlight != nil){
            if(mhighlight!.x > lhighlight!.x && mhighlight!.x < rhighlight!.x){
                uploadButton.isEnabled = true
                uploadButton.setTitleColor(UIColor.cyan, for: .normal)
            }else{
                uploadButton.isEnabled = false
                uploadButton.setTitleColor(UIColor.lightGray, for: .normal)
            }
        }
    }
    
    
    // Mark: Actions
    @IBAction func selectPointsClicked(_ sender: UIButton) {
        generator.impactOccurred()
        sender.isEnabled = false
        anticipateSwitch.isEnabled = true
        markEventObj.pointsSelected = true
        dataManager.updateMarkEvent(markEvent: markEventObj)
        
        // displays

        let numGraphPoints = lineChartEntry["HR"]!.count
        if(numGraphPoints > 0){
            uploadButton.isEnabled = true // we know the middle slider is always in between the l and r sliders
            lcrop.isEnabled = true
            rcrop.isEnabled = true
            
            let closestIdx = getNewXForHightlight3()
            mhighlight = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
            lhighlight = Highlight(x: Double(lineChartEntry["HR"]![0].x), y: lineChartEntry["HR"]![0].y, dataSetIndex: 0)
            rhighlight = Highlight(x: Double(lineChartEntry["HR"]![numGraphPoints - 1].x), y: lineChartEntry["HR"]![numGraphPoints - 1].y, dataSetIndex: 0)
            heartrateChart.highlightValues(getAllHighlights())
            
            mcrop.minimumTrackTintColor = UIColor.lightGray
            mcrop.isEnabled = true
        }else{
            NSLog("No Heartrate data! Can't select points")
        }
    }
    
    // The sole purpose of the lastHighlight is to see if the highlights moved to see if we need to vibrate
    var llastHighlight : Highlight? = nil
    var rlastHighlight : Highlight? = nil
    var mlastHighlight : Highlight? = nil
    
    func getAllHighlights() -> [Highlight]{
        var allHighlights = [Highlight]()
        
        if(lhighlight != llastHighlight || rhighlight != rlastHighlight || mhighlight != mlastHighlight){
            generator.impactOccurred()
        }
        
        if(lhighlight != nil){
            llastHighlight = lhighlight!
            allHighlights.append(lhighlight!)
        }
        if(rhighlight != nil){
            rlastHighlight = rhighlight!
            allHighlights.append(rhighlight!)
        }
        if(mhighlight != nil){
            mlastHighlight = mhighlight!
            allHighlights.append(mhighlight!)
        }
        
        return allHighlights
    }
    
    func getNewXForHightlight3() -> Int{
        let sliderPos = mcrop.value
        let numEntries = lineChartEntry["HR"]!.count
        var closestIdx = Int((Double(sliderPos) * Double(numEntries)))
        if(closestIdx == numEntries){
            closestIdx = closestIdx - 1
        }
        return closestIdx
    }
    
    func setupEventDurationString(){
        eventDurationTextLabel.text = String(format: "%.2f", markEventObj.selectionRange * 5.0) + " min"
    }
    

    
    @IBAction func goBackToOneButtonTapped(_ sender: Any) {
        generator.impactOccurred()
        performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
    }
    
    
    // handle displaying the slider positions on the graph
    
    func getClosestIdx(sliderPos : Float) -> Int {
        let numEntries = lineChartEntry["HR"]!.count
        var closestIdx = Int((Double(sliderPos) * Double(numEntries)))
        if(closestIdx == numEntries){
            closestIdx = closestIdx - 1
        }
        return closestIdx
    }
    
    func setlSlider(){
        let timeStartSliderPos = lcrop.value
        let timeEndSliderPos = rcrop.value
        // this case stops the slider
        if(timeStartSliderPos > timeEndSliderPos){
            lcrop.setValue(timeEndSliderPos, animated: true)
        }else{
            
            let closestIdx = getClosestIdx(sliderPos : timeStartSliderPos)
            
            //NSLog("Index of the point closest to timeStartSlider: \(closestIdx)")
            let newX = Double(lineChartEntry["HR"]![closestIdx].x)
            
            if(rhighlight != nil && newX == rhighlight!.x){ // we don't want the left and right sliders to be on the same point
                heartrateChart.highlightValues(getAllHighlights())
            }else{
                lhighlight = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
                heartrateChart.highlightValues(getAllHighlights())
            }
            
            if(markEventObj.anticipate){
                checkIfCanUpload()
            }
        }
    }
    
    func setrSlider(){
        let timeStartSliderPos = lcrop.value
        let timeEndSliderPos = rcrop.value
        if(timeEndSliderPos < timeStartSliderPos){
            rcrop.setValue(timeStartSliderPos, animated: true)
        }else{
            
            
            
            let closestIdx = getClosestIdx(sliderPos : timeEndSliderPos)

            //NSLog("Index of the point closest to timeEndSlider: \(closestIdx)")
            let newX = Double(lineChartEntry["HR"]![closestIdx].x)
            
            if(lhighlight != nil && newX == lhighlight!.x){ // we don't want the left and right sliders to be on the same point
                heartrateChart.highlightValues(getAllHighlights())
            }else{
                rhighlight = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
                heartrateChart.highlightValues(getAllHighlights())
            }
            
            if(markEventObj.anticipate){
                checkIfCanUpload()
            }
        }
    }
    
    
    // handle the middle slider
    
    func setmSlider(){
        if(markEventObj.pointsSelected){
            if(markEventObj.anticipate){
                updateMHighlight()
                checkIfCanUpload()
            }
            heartrateChart.highlightValues(getAllHighlights())
        }else{
            setupEventDurationString()
            updateGraph()
        }
    }
    
    func updateMHighlight(){
        let closestIdx = getNewXForHightlight3()
        mhighlight = Highlight(x: Double(lineChartEntry["HR"]![closestIdx].x), y: lineChartEntry["HR"]![closestIdx].y, dataSetIndex: 0)
    }
    
    @IBAction func anticipateSwitch(_ sender: Any) {
        if(markEventObj.anticipate){ // turn switch off
            markEventObj.anticipate = false
            mcrop.isEnabled = false
            mhighlight = nil
            mlastHighlight = nil // to prevent vibration spam
            
            heartrateChart.highlightValues(getAllHighlights())
            
        }else{ // turn switch on
            markEventObj.anticipate = true
            checkIfCanUpload()
            mcrop.isEnabled = true
            updateMHighlight()
            heartrateChart.highlightValues(getAllHighlights())
        }
        dataManager.updateMarkEvent(markEvent: markEventObj)
    }
    
    
    // handle slider positions and save them to coredata
    
    @IBAction func timeStartSliderMoved(_ sender: UISlider) {
        if(lineChartEntry["HR"]!.count > 1){
            setlSlider()
            markEventObj.lcrop = Double(sender.value)
            dataManager.updateMarkEvent(markEvent: markEventObj)
        }
    }
    
    @IBAction func eventDurationSliderChanged(_ sender: UISlider) {
        
        // the case when displaying the highlight on the graph
        if(markEventObj.pointsSelected && lineChartEntry["HR"]!.count > 1){
            markEventObj.mcrop = Double(sender.value)
        }
        
        // the case when shifting the range of the graph
        if(!markEventObj.pointsSelected && bioPoints["HR"]!.count > 1){
            markEventObj.selectionRange = Double(sender.value)
        }
        setmSlider()
        dataManager.updateMarkEvent(markEvent: markEventObj)
    }
    
    @IBAction func timeEndSliderMoved(_ sender: UISlider) {
        if(lineChartEntry["HR"]!.count > 1){
            setrSlider()
            markEventObj.rcrop = Double(sender.value)
            dataManager.updateMarkEvent(markEvent: markEventObj)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("Intercepted Segue")
        if segue.identifier == "unwindSegue2ToMainViewController"{ // no params to pass as of this version
            if let destinationVC = segue.destination as? MainViewController {
                destinationVC.reloadMarkEventTable()
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
        if(dataManager.deleteMarkEvent(markTime: markEventObj.markTime)){
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
        //TODO: fix bug that crashes when highlight1 or highlight2 is nil
        let highlight1Date = markEventObj.markTime.addingTimeInterval(TimeInterval(lhighlight!.x))
        let highlight2Date = markEventObj.markTime.addingTimeInterval(TimeInterval(rhighlight!.x))
        var highlight3Date = Date()
        
        
        
        var timeOfEvent = highlight3Date
        if(markEventObj.anticipate){
            timeOfEvent = highlight1Date
        }else{
            highlight3Date = markEventObj.markTime.addingTimeInterval(TimeInterval(mhighlight!.x))
        }
        
        var commentToSend = commentBoxTextView.text
        if(commentToSend == commentBoxPlaceholder){
            commentToSend = ""
        }
    
        
        let buttonStates = evaluateEmotionBar.getButtonStates()
        
        /*
        let markEventObj = MarkEventObj(markTime: markEventObj.markTime,
                                        anticipate: anticipate,
                                        startTime: highlight1Date,
                                        eventTime: timeOfEvent,
                                        endTime: highlight2Date,
                                        emotionsFelt: buttonStates,
                                        comment: commentToSend!)
        */
        //httpManager.uploadMarkEvent(markEventObj: markEventObj)
        //self.deleteCurrentMarkEvent()
        self.performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
        
    }
}

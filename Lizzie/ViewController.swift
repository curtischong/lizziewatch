//
//  ViewController.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
// TODO: Add a button that switches between minutes and seconds... or have it automatically switch

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
    
    let displayDateFormatter = DateFormatter()
    
    var selectedEmotions = Array(repeating: false, count: 8)
    var markEventDate: Date = Date()
    var bioPoints : [chartPoint]?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Setting things up")
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
        
        
        NSLog("Finished Setting things up")
        updateGraph(timeOfMark : markEventDate)
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
            commentBoxTextView.textColor = UIColor.black
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
    /*
     func updateGraph(timeOfMark : Date){
     let point = queryBioSamples(timeOfMark : timeOfMark)
     var lineChartEntry = [ChartDataEntry]()
     var numbers = [3,4,2,1,6]
     
     for i in 0...(numbers.count-1){
     let value = ChartDataEntry(x: Double(i), y: Double(numbers[i]))
     lineChartEntry.append(value)
     }
     
     let line1 = LineChartDataSet(values: lineChartEntry, label: "Number")
     line1.colors = [NSUIColor.blue]
     
     let data = LineChartData()
     data.addDataSet(line1)
     heartrateChart.data = data
     heartrateChart.chartDescription?.text = "Heartrate"
     }*/
    
    func updateGraph(timeOfMark : Date){
        bioPoints = queryBioSamples(timeOfMark : timeOfMark)
        var lineChartEntry = [ChartDataEntry]()

        
        for i in 0...(bioPoints!.count - 1){
            NSLog("Cur Time: \(Double(bioPoints![i].endTime.seconds(from : timeOfMark)))")
            let value = ChartDataEntry(x: Double(bioPoints![i].endTime.seconds(from : timeOfMark)), y: bioPoints![i].measurement)
            lineChartEntry.append(value)
        }
        
        let line = LineChartDataSet(values: lineChartEntry, label: "Heartrate")
        line.colors = [NSUIColor.blue]
        
        let data = LineChartData()
        data.addDataSet(line)
        heartrateChart.data = data
        //heartrateChart.chartDescription?.text = "Heartrate"
    }
    
    func queryBioSamples(timeOfMark : Date) -> [chartPoint]{
        
        let numMinutesGap = 1.0
        let endTime = timeOfMark.addingTimeInterval(TimeInterval(numMinutesGap * 60.0))
        let startTime = timeOfMark.addingTimeInterval(TimeInterval(-numMinutesGap * 60.0))
        
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
    @IBAction func eventDurationSliderChanged(_ sender: UISlider) {
        eventDurationTextLabel.text = "\(eventDurationSlider.value)"
    }
    
    @IBAction func goBackToOneButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegue2ToMainViewController", sender: self)
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

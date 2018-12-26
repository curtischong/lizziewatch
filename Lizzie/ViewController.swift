//
//  ViewController.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import UIKit
import Charts
import Alamofire
import SwiftyJSON
import WatchConnectivity

class ViewController: UIViewController ,UITextFieldDelegate, WCSessionDelegate{

    //MARK: Properties
    @IBOutlet weak var eventTextLabel: UILabel!
    @IBOutlet weak var eventTextField: UITextField!
    
    @IBOutlet weak var eventDurationTextLabel: UILabel!
    @IBOutlet weak var eventDurationSlider: UISlider!
    
    @IBOutlet weak var heartrateChart: LineChartView!
    
    var selectedEmotions = Array(repeating: false, count: 8)
    
    @IBOutlet weak var theSwitch: UISwitch!
    @IBOutlet weak var requestTest: UIButton!
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Setting things up")
        
        // IOS Setup
        eventTextField.delegate = self
        
        //TODO: Move this to an initializer
        // Watch Setup
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        NSLog("Finished Setting things up")
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
        eventTextLabel.text = textField.text
    }
    @IBAction func eventDurationSliderChanged(_ sender: UISlider) {
        eventDurationTextLabel.text = "\(eventDurationSlider.value)"
        updateGraph()
    }
    
    func updateGraph(){
        var lineChartEntry = [ChartDataEntry]()
        var numbers = [3,4,2,1,6]
        for i in 0...(numbers.count-1){
            let value  = ChartDataEntry(x: Double(i), y: Double(numbers[i]))
            
            lineChartEntry.append(value)
        }
        let line1 = LineChartDataSet(values: lineChartEntry, label: "Number")
        line1.colors = [NSUIColor.blue]
        
        let data = LineChartData()
        data.addDataSet(line1)
        heartrateChart.data = data
        heartrateChart.chartDescription?.text = "Heartrate"
    }
    
    
    
    
    /*func readConfig() -> String{
        print("reading config")
        if let path = Bundle.main.path(forResource: "configasd", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let ip = jsonResult["ip"] as? String {
                    return ip
                }
            } catch {
                print("couldn't read config file")
            }
        }
        return ""
    }*/
    /*func readConfig() -> JSON{
        if let path = Bundle.main.path(forResource: "config", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let jsonObj = try JSON(data: data)
                print("jsonData:\(jsonObj)")
                return jsonObj
            } catch let error {
                print("parse error: \(error.localizedDescription)")
            }
        } else {
            print("Invalid filename/path.")
        }
        return JSON()
    }*/

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
    
    func processApplicationContext() {
        if let iPhoneContext = session?.applicationContext as? [String : Bool] {
            if iPhoneContext["switchStatus"] == true {
                theSwitch.isOn = true
            } else {
                theSwitch.isOn = false
            }
        }
    }
    
    // Watch connectivity
    
    var session: WCSession?
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if let validSession = session {
            let iPhoneAppContext = ["switchStatus": sender.isOn]
            
            do {
                try validSession.updateApplicationContext(iPhoneAppContext)
            } catch {
                //TODO: update a ui element when this happens
                print("Something went wrong")
            }
        }
    }
}


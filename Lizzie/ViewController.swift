//
//  ViewController.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController ,UITextFieldDelegate{

    //MARK: Properties
    @IBOutlet weak var eventTextLabel: UILabel!
    @IBOutlet weak var eventTextField: UITextField!
    
    @IBOutlet weak var eventDurationTextLabel: UILabel!
    @IBOutlet weak var eventDurationSlider: UISlider!
    
    @IBOutlet weak var heartrateChart: LineChartView!
    
    var selectedEmotions = Array(repeating: false, count: 8)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        eventTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

}


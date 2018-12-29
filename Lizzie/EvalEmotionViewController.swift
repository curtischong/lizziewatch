//
//  EvalEmotionViewController.swift
//  Lizzie
//
//  Created by Curtis Chong on 2018-12-29.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import UIKit

class EvalEmotionViewController: UIViewController {

    @IBOutlet weak var normalEvalSliderLabel: UILabel!
    @IBOutlet weak var tiredEvalSliderLabel: UILabel!
    @IBOutlet weak var happyEvalSliderLabel: UILabel!
    
    @IBOutlet weak var normalEvalSlider: UISlider!
    @IBOutlet weak var tiredEvalSlider: UISlider!
    @IBOutlet weak var happyEvalSlider: UISlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        normalEvalSliderLabel.text = "0"
        normalEvalSlider.setValue(0.0, animated: true)
        
        tiredEvalSliderLabel.text = "0"
        tiredEvalSlider.setValue(0.0, animated: true)
        
        happyEvalSliderLabel.text = "0"
        happyEvalSlider.setValue(0.5, animated: true)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func goBackToOneButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToMainViewController", sender: self)
    }

    @IBAction func normalEvalSliderMoved(_ sender: UISlider) {
        let sliderPos = normalEvalSlider.value
        let sliderVal = round(sliderPos*5)/5
        let realVal = Int(round(sliderPos*5))
        normalEvalSliderLabel.text = "\(realVal)"
        sender.setValue(sliderVal, animated: true)
    }
    
    @IBAction func tiredEvalSliderMoved(_ sender: UISlider) {
        let sliderPos = tiredEvalSlider.value
        let sliderVal = round(sliderPos*5)/5
        let realVal = Int(round(sliderPos*5))
        tiredEvalSliderLabel.text = "\(realVal)"
        sender.setValue(sliderVal, animated: true)
    }
    
    @IBAction func happyEvalSliderMoved(_ sender: UISlider) {
        let sliderPos = happyEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        let realVal = Int(round(sliderPos*10)) - 5
        happyEvalSliderLabel.text = "\(realVal)"
        sender.setValue(sliderVal, animated: true)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

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
    @IBOutlet weak var normalEvalSlider: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func normalEvalSliderMoved(_ sender: UISlider) {
        let sliderPos = Float(lroundf(normalEvalSlider.value))
        normalEvalSliderLabel.text = NSString(format: "%.2f", sliderPos) as String
        sender.setValue(sliderPos, animated: true)
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

//
//  EvalEmotionViewController.swift
//  Lizzie
//
//  Created by Curtis Chong on 2018-12-29.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import UIKit
import AudioToolbox

class EvalEmotionViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var normalEvalSliderLabel: UILabel!
    @IBOutlet weak var socialEvalSliderLabel: UILabel!
    @IBOutlet weak var exhaustedEvalSliderLabel: UILabel!
    @IBOutlet weak var tiredEvalSliderLabel: UILabel!
    @IBOutlet weak var happyEvalSliderLabel: UILabel!
    
    @IBOutlet weak var normalEvalSlider: UISlider!
    @IBOutlet weak var socialEvalSlider: UISlider!
    @IBOutlet weak var exhaustedEvalSlider: UISlider!
    @IBOutlet weak var tiredEvalSlider: UISlider!
    @IBOutlet weak var happyEvalSlider: UISlider!
    
    @IBOutlet weak var commentBoxTextView: UITextView!
    
    let generator = UIImpactFeedbackGenerator(style: .light)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        normalEvalSliderLabel.text = "How normal do you feel? 0"
        normalEvalSlider.setValue(0.0, animated: true)
        //normalEvalSlider.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        socialEvalSliderLabel.text = "How social do you feel? 0"
        socialEvalSlider.setValue(0.0, animated: true)
        
        tiredEvalSliderLabel.text = "How tired do you feel? 0"
        tiredEvalSlider.setValue(0.0, animated: true)
        
        exhaustedEvalSliderLabel.text = "How exhausted do you feel? 0"
        exhaustedEvalSlider.setValue(0.0, animated: true)
        
        happyEvalSliderLabel.text = "How happy do you feel? 0"
        happyEvalSlider.setValue(0.5, animated: true)

        // Textview
        commentBoxTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        commentBoxTextView.layer.borderWidth = 1.0
        commentBoxTextView.layer.cornerRadius = 5
        
        commentBoxTextView.delegate = self
        commentBoxTextView.text = "Comments"
        commentBoxTextView.textColor = UIColor.lightGray
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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
    
    
    @IBAction func goBackToOneButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToMainViewController", sender: self)
    }

    @IBAction func normalEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How normal do you feel? "
        let sliderPos = normalEvalSlider.value
        let sliderVal = round(sliderPos*5)/5
        let realVal = Int(round(sliderPos*5))
        sender.setValue(sliderVal, animated: true)
        
        if(normalEvalSliderLabel.text != phrase + "\(realVal)"){
            normalEvalSliderLabel.text = phrase + "\(realVal)"
            generator.impactOccurred()
        }
    }
    @IBAction func socialEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How social do you feel? "
        let sliderPos = socialEvalSlider.value
        let sliderVal = round(sliderPos*5)/5
        let realVal = Int(round(sliderPos*5))
        sender.setValue(sliderVal, animated: true)
        
        if(socialEvalSliderLabel.text != phrase + "\(realVal)"){
            socialEvalSliderLabel.text = phrase + "\(realVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func exhaustedEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How exhausted do you feel? "
        let sliderPos = exhaustedEvalSlider.value
        let sliderVal = round(sliderPos*5)/5
        let realVal = Int(round(sliderPos*5))
        sender.setValue(sliderVal, animated: true)
        
        if(exhaustedEvalSliderLabel.text != phrase + "\(realVal)"){
            exhaustedEvalSliderLabel.text = phrase + "\(realVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func tiredEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How tired do you feel? "
        let sliderPos = tiredEvalSlider.value
        let sliderVal = round(sliderPos*5)/5
        let realVal = Int(round(sliderPos*5))
        sender.setValue(sliderVal, animated: true)
        
        if(tiredEvalSliderLabel.text != phrase + "\(realVal)"){
            tiredEvalSliderLabel.text = phrase + "\(realVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func happyEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How happy do you feel? "
        let sliderPos = happyEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        let realVal = Int(round(sliderPos*10)) - 5
        sender.setValue(sliderVal, animated: true)

        if(happyEvalSliderLabel.text != phrase + "\(realVal)"){
            happyEvalSliderLabel.text = phrase + "\(realVal)"
            generator.impactOccurred()
        }
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

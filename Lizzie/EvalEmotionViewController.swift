//
//  EvalEmotionViewController.swift
//  Lizzie
//
//  Created by Curtis Chong on 2018-12-29.
//  Copyright © 2018 Thomas Paul Mann. All rights reserved.
//

import UIKit
import AudioToolbox
import Alamofire

class EvalEmotionViewController: UIViewController, UITextViewDelegate {

    
    
    @IBOutlet weak var accomplishedEvalSliderLabel: UILabel!
    @IBOutlet weak var socialEvalSliderLabel: UILabel!
    @IBOutlet weak var exhaustedEvalSliderLabel: UILabel!
    @IBOutlet weak var tiredEvalSliderLabel: UILabel!
    @IBOutlet weak var happyEvalSliderLabel: UILabel!
    
    
    @IBOutlet weak var accomplishedEvalSlider: UISlider!
    @IBOutlet weak var socialEvalSlider: UISlider!
    @IBOutlet weak var exhaustedEvalSlider: UISlider!
    @IBOutlet weak var tiredEvalSlider: UISlider!
    @IBOutlet weak var happyEvalSlider: UISlider!
    
    @IBOutlet weak var commentBoxTextView: UITextView!
    
    private var accomplishedSliderRealVal = 0
    private var socialSliderRealVal = 0
    private var exhaustedSliderRealVal = 0
    private var tiredSliderRealVal = 0
    private var happySliderRealVal = 0
    private let commentBoxPlaceholder = "Comments"
    let httpManager = HttpManager()
    var toolbar : UIToolbar!
    
    
    let generator = UIImpactFeedbackGenerator(style: .light)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accomplishedEvalSliderLabel.text = "How accomplished do you feel? 0"
        accomplishedEvalSlider.setValue(0.5, animated: true)
        //normalEvalSlider.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        socialEvalSliderLabel.text = "How social do you feel? 0"
        socialEvalSlider.setValue(0.5, animated: true)
        
        tiredEvalSliderLabel.text = "How tired do you feel? 0"
        tiredEvalSlider.setValue(0.5, animated: true)
        
        exhaustedEvalSliderLabel.text = "How exhausted do you feel? 0"
        exhaustedEvalSlider.setValue(0.5, animated: true)
        
        happyEvalSliderLabel.text = "How happy do you feel? 0"
        happyEvalSlider.setValue(0.5, animated: true)

        // Textview
        commentBoxTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        commentBoxTextView.layer.borderWidth = 1.0
        commentBoxTextView.layer.cornerRadius = 5
        
        commentBoxTextView.delegate = self
        commentBoxTextView.text = commentBoxPlaceholder
        commentBoxTextView.textColor = UIColor.lightGray
        
        
        // keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        //init toolbar
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
        let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.commentBoxTextView.inputAccessoryView = toolbar
    }
    
    // Keyboard Functions
    
    @objc func doneButtonAction() {
        generator.impactOccurred()
        self.view.endEditing(true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
        generator.impactOccurred()
        if commentBoxTextView.text.isEmpty {
            commentBoxTextView.text = commentBoxPlaceholder
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
        generator.impactOccurred()
        performSegue(withIdentifier: "unwindSegueToMainViewController", sender: self)
    }

    
    @IBAction func accomplishedEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How accomplished do you feel? "
        let sliderPos = accomplishedEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        accomplishedSliderRealVal = Int(round(sliderPos*10)) - 5
        sender.setValue(sliderVal, animated: true)
        
        if(accomplishedEvalSliderLabel.text != phrase + "\(accomplishedSliderRealVal)"){
            accomplishedEvalSliderLabel.text = phrase + "\(accomplishedSliderRealVal)"
            generator.impactOccurred()
        }
    }
    @IBAction func socialEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How social do you feel? "
        let sliderPos = socialEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        socialSliderRealVal = Int(round(sliderPos*10)) - 5
        sender.setValue(sliderVal, animated: true)
        
        if(socialEvalSliderLabel.text != phrase + "\(socialSliderRealVal)"){
            socialEvalSliderLabel.text = phrase + "\(socialSliderRealVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func exhaustedEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How exhausted do you feel? "
        let sliderPos = exhaustedEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        exhaustedSliderRealVal = Int(round(sliderPos*10)) - 5
        sender.setValue(sliderVal, animated: true)
        
        if(exhaustedEvalSliderLabel.text != phrase + "\(exhaustedSliderRealVal)"){
            exhaustedEvalSliderLabel.text = phrase + "\(exhaustedSliderRealVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func tiredEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How tired do you feel? "
        let sliderPos = tiredEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        tiredSliderRealVal = Int(round(sliderPos*10)) - 5
        sender.setValue(sliderVal, animated: true)
        
        if(tiredEvalSliderLabel.text != phrase + "\(tiredSliderRealVal)"){
            tiredEvalSliderLabel.text = phrase + "\(tiredSliderRealVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func happyEvalSliderMoved(_ sender: UISlider) {
        let phrase = "How happy do you feel? "
        let sliderPos = happyEvalSlider.value
        let sliderVal = round(sliderPos*10)/10
        happySliderRealVal = Int(round(sliderPos*10)) - 5
        sender.setValue(sliderVal, animated: true)

        if(happyEvalSliderLabel.text != phrase + "\(happySliderRealVal)"){
            happyEvalSliderLabel.text = phrase + "\(happySliderRealVal)"
            generator.impactOccurred()
        }
    }
    
    @IBAction func uploadResponseButtonPressed(_ sender: Any) {
        generator.impactOccurred()
        var commentsToSend = commentBoxTextView.text
        if(commentsToSend == commentBoxPlaceholder){
            commentsToSend = ""
        }
        
        let emotionEvalObj = EmotionEvalObj(
                                            ts: Date(),
                                            accomplished: accomplishedSliderRealVal,
                                            social: socialSliderRealVal,
                                            exhausted: exhaustedSliderRealVal,
                                            tired: tiredSliderRealVal,
                                            happy: happySliderRealVal,
                                            comment: commentsToSend! as String)
        // httpManager.uploadEmotionEvaluation(emotionEvalObj : emotionEvalObj)
        self.performSegue(withIdentifier: "unwindSegueToMainViewController", sender: self)
    }
}

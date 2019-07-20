//
//  EmotionSelectionController.swift
//  lizziewatch
//
//  Created by Curtis Chong on 2018-12-21.
//  Copyright © 2018 Curtis Chong. All rights reserved.
//

import UIKit

protocol emotionSelectionElementDelegate: class {
    func updateEmotionsFelt(emotionsFelt: [String : Int])
}

@IBDesignable class EmotionSelectionElement: UIStackView {
    private var buttonEmotions = ["Fear","Joy","Anger","Sad","Disgust","Suprise","Contempt","Interest"]
    var numEmotions = 8
    private var ratingButtons = [UIButton]()
    var selectedEmotions = Array(repeating: 0, count: 8) // TODO: use numEmotions instead of 8
    
    
    weak var delegate: emotionSelectionElementDelegate?
    private var selectedColors = [UIColor.white,
                                  UIColor(red:0.00, green:1.0, blue:1.0, alpha:1.0),
                                  UIColor(red:1.00, green:0.54, blue:0.00, alpha:1.0),
                                  UIColor(red:1.00, green:0.0, blue:0.00, alpha:1.0)]
    let generator = UIImpactFeedbackGenerator(style: .light)
    //MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    //MARK: Button Action
    @objc func ratingButtonTapped(button: UIButton) {
        generator.impactOccurred()
        guard let index = ratingButtons.firstIndex(of: button) else {
            fatalError("The button, \(button), is not in the ratingButtons array: \(ratingButtons)")
        }
        
        selectedEmotions[index] = selectedEmotions[index] + 1
        if(selectedEmotions[index] == 4){
            selectedEmotions[index] = 0
        }
        ratingButtons[index].setTitleColor(selectedColors[selectedEmotions[index]], for: .normal)
        delegate?.updateEmotionsFelt(emotionsFelt: getButtonStates())
        NSLog("asdsad")
        NSLog("\(getButtonStates())")
    }
    
    private func setupButtons() {
        
        // Clear any existing buttons
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        
        
        for index in 0..<numEmotions {
            // Create the button
            let button = UIButton()
            button.setTitleColor(selectedColors[selectedEmotions[index]], for: .normal)
            button.titleLabel?.font =  .systemFont(ofSize: 10)
            
            
            // Set the button images
            button.setTitle(buttonEmotions[index], for: [])
            
            // Add constraints
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Set the accessibility label
            button.accessibilityLabel = "Set \(index + 1) star rating"
            
            // Setup the button action
            button.addTarget(self, action: #selector(EmotionSelectionElement.ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the stack
            addArrangedSubview(button)
            
            // Add the new button to the rating button array
            ratingButtons.append(button)
        }
    }
    func getButtonStates() -> [String : Int]{
        return ["fear": selectedEmotions[0],
                          "joy": selectedEmotions[1],
                          "anger": selectedEmotions[2],
                          "sad": selectedEmotions[3],
                          "disgust": selectedEmotions[4],
                          "surprise": selectedEmotions[5],
                          "contempt": selectedEmotions[6],
                          "interest": selectedEmotions[7]]
    }
    
    func setButtonStates(buttonStates : [String : Int]){
        selectedEmotions[0] = buttonStates["fear"]!
        selectedEmotions[1] = buttonStates["joy"]!
        selectedEmotions[2] = buttonStates["anger"]!
        selectedEmotions[3] = buttonStates["sad"]!
        selectedEmotions[4] = buttonStates["disgust"]!
        selectedEmotions[5] = buttonStates["surprise"]!
        selectedEmotions[6] = buttonStates["contempt"]!
        selectedEmotions[7] = buttonStates["interest"]!
        
        for index in 0..<numEmotions{
            ratingButtons[index].setTitleColor(selectedColors[selectedEmotions[index]], for: .normal)
        }
        NSLog("\(selectedEmotions)")
    }
}

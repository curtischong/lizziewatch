//
//  EmotionSelectionController.swift
//  lizziewatch
//
//  Created by Curtis Chong on 2018-12-21.
//  Copyright © 2018 Curtis Chong. All rights reserved.
//

import UIKit


@IBDesignable class EmotionButtonsControl: UIStackView {
    private var buttonEmotions = ["Fear","Joy","Anger","Sad","Disgust","Suprise","Contempt","Interest"]
    lazy var numEmotions = 8
    private var ratingButtons = [UIButton]()
    private var selectedEmotions = Array(repeating: 0, count: 8) // TODO: use numEmotions instead of 8
    
    
    
    private var selectedColors = [UIColor.white,
                                  UIColor(red:0.00, green:1.0, blue:1.0, alpha:1.0),
                                  UIColor(red:1.00, green:0.54, blue:0.00, alpha:1.0),
                                  UIColor(red:1.00, green:0.0, blue:0.00, alpha:1.0)]
    
    //TODO: add the tripple emotion state code
    //TODO: remove the useless slider pod
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
        guard let index = ratingButtons.index(of: button) else {
            fatalError("The button, \(button), is not in the ratingButtons array: \(ratingButtons)")
        }
        
        selectedEmotions[index] = selectedEmotions[index] + 1
        if(selectedEmotions[index] == 4){
            selectedEmotions[index] = 0
        }
        ratingButtons[index].setTitleColor(selectedColors[selectedEmotions[index]], for: .normal)
        
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
            //button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            //button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            // Set the accessibility label
            button.accessibilityLabel = "Set \(index + 1) star rating"
            
            // Setup the button action
            button.addTarget(self, action: #selector(EmotionButtonsControl.ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the stack
            addArrangedSubview(button)
            
            // Add the new button to the rating button array
            ratingButtons.append(button)
        }
        
        //updateButtonSelectionStates()
    }
}

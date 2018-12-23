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
    private var selectedEmotions = Array(repeating: false, count: 8) // TODO: use numEmotions instead of 8
    private var unselectedColor = UIColor.cyan
    private var selectedColor = UIColor.blue
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
        
        if(selectedEmotions[index]){
            selectedEmotions[index] = false
            ratingButtons[index].setTitleColor(unselectedColor, for: .normal)
        }else{
            selectedEmotions[index] = true
            ratingButtons[index].setTitleColor(selectedColor, for: .normal)
        }
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
            button.setTitleColor(unselectedColor, for: .normal)
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

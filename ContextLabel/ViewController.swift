//
//  ViewController.swift
//  ContextLabel
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ContextLabelDelegate {
    
    lazy var contextLabel: ContextLabel = {
        let _contextLabel = ContextLabel()
        _contextLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        _contextLabel.numberOfLines = 0
        _contextLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        _contextLabel.text = "ContextLabel is a Swift drop-in replacement for UILabel that supports selectable @UserHandle, #Hashtags and links https://github.com/michaelloistl/ContextLabel"
        _contextLabel.delegate = self
        return _contextLabel
        }()
    
    lazy var resultLabel: UILabel = {
        let _resultLabel = UILabel()
        _resultLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        _resultLabel.textAlignment = .Center
        _resultLabel.numberOfLines = 0
        _resultLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        return _resultLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(contextLabel)
        view.addSubview(resultLabel)
        
        var contet = ContextLabel(frame: CGRectMake(0, 0, 320, 100))
        
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // contextLabel
        self.view.addConstraint(NSLayoutConstraint(item: self.contextLabel, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 10.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.contextLabel, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: -10.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.contextLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
        
        // resultLabel
        self.view.addConstraint(NSLayoutConstraint(item: self.resultLabel, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 10.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.resultLabel, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: -10.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.resultLabel, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: -10.0))
    }
    
    // MRAK: ContextLabelDelegate

    func contextLabel(contextLabel: ContextLabel, didSelectText: String, inRange: NSRange) {
        resultLabel.text = "\(didSelectText)" + "\nRange: \(inRange)"
    }
}



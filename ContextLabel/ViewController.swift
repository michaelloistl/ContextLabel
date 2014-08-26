//
//  ViewController.swift
//  ContextLabel
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    lazy var contextLabel: ContextLabel = {
        let _contextLabel = ContextLabel()
        _contextLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        _contextLabel.backgroundColor = UIColor.whiteColor()
        _contextLabel.highlightedTextColor = UIColor.redColor()
        _contextLabel.numberOfLines = 0
        _contextLabel.text = "@michael and @andy are testing #Context #Label on www.github.com"
        return _contextLabel
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(contextLabel)
        
//        contextLabel.touchHandler = {(linkRangeResult) -> Void in
//            NSLog("TOUCHE HANDLER ...")
//        }
        
        updateViewConstraints()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        self.view.addConstraint(NSLayoutConstraint(item: self.contextLabel, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 10.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.contextLabel, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: -10.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.contextLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
    }
}



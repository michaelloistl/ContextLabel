//
//  ContextLabelTests.swift
//  ContextLabelTests
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//

import UIKit
import XCTest
import ContextLabel

class ContextLabelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testAttributesFromProperties() {
        
        let contextLabel = ContextLabel()
        contextLabel.shadowColor = UIColor.redColor()
        contextLabel.shadowOffset = CGSizeMake(1, 2)
        contextLabel.textColor = UIColor.blueColor()
        contextLabel.textAlignment = .Center
        
        let attributes = contextLabel.attributesFromProperties()
        
        let foregroundColor = attributes[NSForegroundColorAttributeName] as UIColor
        XCTAssertEqual(foregroundColor, UIColor.blueColor(), "")
        
        let shadow = attributes[NSShadowAttributeName] as NSShadow
        let shadowColor = shadow.shadowColor as UIColor
        XCTAssertEqual(shadowColor, UIColor.redColor(), "")
        XCTAssertEqual(shadow.shadowOffset.width, CGFloat(1), "")
        XCTAssertEqual(shadow.shadowOffset.height, CGFloat(2), "")
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as NSParagraphStyle
        let paragraphStyleAlignment = paragraphStyle.alignment
        XCTAssertEqual(paragraphStyleAlignment, NSTextAlignment.Center, "")
        
        // Highlighted
        contextLabel.highlightedTextColor = UIColor.yellowColor()
        contextLabel.highlighted = true
        
        let attributesHighlighted = contextLabel.attributesFromProperties()
        
        let foregroundColorHighlighted = attributesHighlighted[NSForegroundColorAttributeName] as UIColor
        XCTAssertEqual(foregroundColorHighlighted, UIColor.yellowColor(), "")

        // Disabled
        contextLabel.enabled = false
        
        let attributesDisabled = contextLabel.attributesFromProperties()
        
        let foregroundColorDisabled = attributesDisabled[NSForegroundColorAttributeName] as UIColor
        XCTAssertEqual(foregroundColorDisabled, UIColor.lightGrayColor(), "")
    }
    
    func testGetRangesForLinksInAttributedString() {
        
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
}

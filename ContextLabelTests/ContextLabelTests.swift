//
//  ContextLabelTests.swift
//  ContextLabelTests
//
//  Created by Michael Loistl on 13/10/2015.
//  Copyright © 2015 Aplo. All rights reserved.
//

import XCTest
@testable import ContextLabel

class ContextLabelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetRangesForTextLinksWithoutEmojis() {
        let textLink1 = TextLink(text: "link1", action: { })
        let textLink2 = TextLink(text: "link2", action: { })
        let textLink3 = TextLink(text: "link3", action: { })
        
        let textLinks = [textLink1, textLink2, textLink3]
        
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing link1 and link2 without emojis"
        
        let linkRangeResults = contextLabel.getRangesForTextLinks(textLinks)
        
        XCTAssertEqual(linkRangeResults.count, 2)
        
        let linkRangeResult1 = linkRangeResults[0]
        XCTAssertEqual(linkRangeResult1.linkString, "link1")
        XCTAssertNotNil(linkRangeResult1.textLink)
        XCTAssertEqual(linkRangeResult1.textLink?.text, "link1")
        XCTAssertEqual(linkRangeResult1.linkRange.location, 8)
        XCTAssertEqual(linkRangeResult1.linkRange.length, 5)
        
        let linkRangeResult2 = linkRangeResults[1]
        XCTAssertEqual(linkRangeResult2.linkString, "link2")
        XCTAssertNotNil(linkRangeResult2.textLink)
        XCTAssertEqual(linkRangeResult2.textLink?.text, "link2")
        XCTAssertEqual(linkRangeResult2.linkRange.location, 18)
        XCTAssertEqual(linkRangeResult2.linkRange.length, 5)
    }
    
    func testGetRangesForTextLinksWithEmojis() {
        let textLink1 = TextLink(text: "link😊", action: { })
        let textLink2 = TextLink(text: "link2", action: { })
        let textLink3 = TextLink(text: "link3", action: { })
        
        let textLinks = [textLink1, textLink2, textLink3]
        
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing ☕️🍪 link😊 and ☕️🍪 link2 with emojis 👍"
        
        let linkRangeResults = contextLabel.getRangesForTextLinks(textLinks)
        
        XCTAssertEqual(linkRangeResults.count, 2)
        
        let linkRangeResult1 = linkRangeResults[0]
        XCTAssertEqual(linkRangeResult1.linkString, "link😊")
        XCTAssertNotNil(linkRangeResult1.textLink)
        XCTAssertEqual(linkRangeResult1.textLink?.text, "link😊")
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult1.linkRange), "link😊")
        
        let linkRangeResult2 = linkRangeResults[1]
        XCTAssertEqual(linkRangeResult2.linkString, "link2")
        XCTAssertNotNil(linkRangeResult2.textLink)
        XCTAssertEqual(linkRangeResult2.textLink?.text, "link2")
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult2.linkRange), "link2")
    }
    
    func testGetRangesForUserHandlesInTextWithoutEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing #tag1 @user1 #and @user2 #tag4 # @ @@user @#user without emojis"
        
        let linkRangeResults = contextLabel.getRangesForUserHandlesInText(contextLabel.text)
        
        XCTAssertEqual(linkRangeResults.count, 2)
        
        let linkRangeResult1 = linkRangeResults[0]
        XCTAssertEqual(linkRangeResult1.linkString, "@user1")
        XCTAssertNil(linkRangeResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult1.linkRange), "@user1")
        
        let linkRangeResult2 = linkRangeResults[1]
        XCTAssertEqual(linkRangeResult2.linkString, "@user2")
        XCTAssertNil(linkRangeResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult2.linkRange), "@user2")
    }
    
    func testGetRangesForUserHandlesInTextWithEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing ☕️🍪 #tag1 ☕️🍪 @user1😊 #and @user2☕️emoji #tag4 # @ @@user @#user with emojis 👍"
        
        let linkRangeResults = contextLabel.getRangesForUserHandlesInText(contextLabel.text)
        
        XCTAssertEqual(linkRangeResults.count, 2)
        
        let linkRangeResult1 = linkRangeResults[0]
        XCTAssertEqual(linkRangeResult1.linkString, "@user1")
        XCTAssertNil(linkRangeResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult1.linkRange), "@user1")
        
        let linkRangeResult2 = linkRangeResults[1]
        XCTAssertEqual(linkRangeResult2.linkString, "@user2")
        XCTAssertNil(linkRangeResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult2.linkRange), "@user2")
    }
    
    func testGetRangesForHashtagsInTextWithoutEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing #tag1 @and #tag2 @user # @ @@user @#tag without emojis"
        
        let linkRangeResults = contextLabel.getRangesForHashtagsInText(contextLabel.text)
        
        XCTAssertEqual(linkRangeResults.count, 2)
        
        let linkRangeResult1 = linkRangeResults[0]
        XCTAssertEqual(linkRangeResult1.linkString, "#tag1")
        XCTAssertNil(linkRangeResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult1.linkRange), "#tag1")
        
        let linkRangeResult2 = linkRangeResults[1]
        XCTAssertEqual(linkRangeResult2.linkString, "#tag2")
        XCTAssertNil(linkRangeResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult2.linkRange), "#tag2")
    }

    func testGetRangesForHashtagsInTextWithEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing ☕️🍪 #tag1 ☕️🍪 @and #tag2😊 @user #tag3☕️emoji # @ @@user @#tag with emojis 👍"
        
        let linkRangeResults = contextLabel.getRangesForHashtagsInText(contextLabel.text)
        
        XCTAssertEqual(linkRangeResults.count, 3)
        
        let linkRangeResult1 = linkRangeResults[0]
        XCTAssertEqual(linkRangeResult1.linkString, "#tag1")
        XCTAssertNil(linkRangeResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult1.linkRange), "#tag1")
        
        let linkRangeResult2 = linkRangeResults[1]
        XCTAssertEqual(linkRangeResult2.linkString, "#tag2")
        XCTAssertNil(linkRangeResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult2.linkRange), "#tag2")
        
        let linkRangeResult3 = linkRangeResults[2]
        XCTAssertEqual(linkRangeResult3.linkString, "#tag3")
        XCTAssertNil(linkRangeResult3.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkRangeResult3.linkRange), "#tag3")
    }
    
    func testGetRangesForTextLinksWithMultipleOccuranciesWithoutRange() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "one two three one two three one two one"
        
        let oneTextLink = TextLink(text: "one", range: nil) { }
        let twoTextLink = TextLink(text: "two", range: nil) { }
        let threeTextLink = TextLink(text: "three", range: nil) { }
        
        let oneLinkRangeResults = contextLabel.getRangesForTextLinks([oneTextLink])
        let twoLinkRangeResults = contextLabel.getRangesForTextLinks([twoTextLink])
        let threeLinkRangeResults = contextLabel.getRangesForTextLinks([threeTextLink])
        let linkRangeResults = contextLabel.getRangesForTextLinks([oneTextLink, twoTextLink, threeTextLink])
        
        XCTAssertEqual(oneLinkRangeResults.count, 4)
        XCTAssertEqual(twoLinkRangeResults.count, 3)
        XCTAssertEqual(threeLinkRangeResults.count, 2)
        XCTAssertEqual(linkRangeResults.count, 4+3+2)
    }
    
    func testGetRangesForTextLinksWithMultipleOccuranciesWithRange() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "one two three one two three one two one"
        
        let range = NSMakeRange(0, "one two three on".characters.count)
        
        let oneTextLink = TextLink(text: "one", range: range) { }
        let twoTextLink = TextLink(text: "two", range: range) { }
        let threeTextLink = TextLink(text: "three", range: range) { }
        
        let oneLinkRangeResults = contextLabel.getRangesForTextLinks([oneTextLink])
        let twoLinkRangeResults = contextLabel.getRangesForTextLinks([twoTextLink])
        let threeLinkRangeResults = contextLabel.getRangesForTextLinks([threeTextLink])
        let linkRangeResults = contextLabel.getRangesForTextLinks([oneTextLink, twoTextLink, threeTextLink])
        
        XCTAssertEqual(oneLinkRangeResults.count, 1)
        XCTAssertEqual(twoLinkRangeResults.count, 1)
        XCTAssertEqual(threeLinkRangeResults.count, 1)
        XCTAssertEqual(linkRangeResults.count, 1+1+1)
    }
     
}

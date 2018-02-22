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
    
    func testLinkResultsForTextLinksWithoutEmojis() {
        let textLink1 = TextLink(text: "link1", action: { })
        let textLink2 = TextLink(text: "link2", action: { })
        let textLink3 = TextLink(text: "link3", action: { })
        
        let textLinks = [textLink1, textLink2, textLink3]
        
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing link1 and link2 without emojis"
        
        let linkResults = contextLabel.linkResultsForTextLinks(textLinks)
        
        XCTAssertEqual(linkResults.count, 2)
        
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "link1")
        XCTAssertNotNil(linkResult1.textLink)
        XCTAssertEqual(linkResult1.textLink?.text, "link1")
        XCTAssertEqual(linkResult1.range.location, 8)
        XCTAssertEqual(linkResult1.range.length, 5)
        
        let linkResult2 = linkResults[1]
        XCTAssertEqual(linkResult2.text, "link2")
        XCTAssertNotNil(linkResult2.textLink)
        XCTAssertEqual(linkResult2.textLink?.text, "link2")
        XCTAssertEqual(linkResult2.range.location, 18)
        XCTAssertEqual(linkResult2.range.length, 5)
    }
    
    func testLinkDetectionForTextLinksWithEmoji() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = """
        🙃
        http://www.bbc.com/news/world-europe-43003740
        """
        
        let linkResults = contextLabel.contextLabelData!.linkResults
        
        XCTAssertEqual(linkResults.count, 1)
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "http://www.bbc.com/news/world-europe-43003740")
        XCTAssertNil(linkResult1.textLink)
    }
    
    func testLinkResultsForTextLinksWithEmojis() {
        let textLink1 = TextLink(text: "link😊", action: { })
        let textLink2 = TextLink(text: "link2", action: { })
        let textLink3 = TextLink(text: "link3", action: { })
        
        let textLinks = [textLink1, textLink2, textLink3]
        
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing ☕️🍪 link😊 and ☕️🍪 link2 with emojis 👍"
        
        let linkResults = contextLabel.linkResultsForTextLinks(textLinks)
        
        XCTAssertEqual(linkResults.count, 2)
        
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "link😊")
        XCTAssertNotNil(linkResult1.textLink)
        XCTAssertEqual(linkResult1.textLink?.text, "link😊")
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult1.range), "link😊")
        
        let linkResult2 = linkResults[1]
        XCTAssertEqual(linkResult2.text, "link2")
        XCTAssertNotNil(linkResult2.textLink)
        XCTAssertEqual(linkResult2.textLink?.text, "link2")
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult2.range), "link2")
    }
    
    func testLinkResultsForUserHandlesWithoutEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing #tag1 @user1 #and @user2 #tag4 # @ @@user @#user without emojis"
        
        let linkResults = contextLabel.linkResultsForUserHandles(inString: contextLabel.text)
        
        XCTAssertEqual(linkResults.count, 2)
        
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "@user1")
        XCTAssertNil(linkResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult1.range), "@user1")
        
        let linkResult2 = linkResults[1]
        XCTAssertEqual(linkResult2.text, "@user2")
        XCTAssertNil(linkResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult2.range), "@user2")
    }
    
    func testLinkResultsForUserHandlesWithEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing ☕️🍪 #tag1 ☕️🍪 @user1😊 #and @user2☕️emoji #tag4 # @ @@user @#user with emojis 👍"
        
        let linkResults = contextLabel.linkResultsForUserHandles(inString: contextLabel.text)
        
        XCTAssertEqual(linkResults.count, 2)
        
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "@user1")
        XCTAssertNil(linkResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult1.range), "@user1")
        
        let linkResult2 = linkResults[1]
        XCTAssertEqual(linkResult2.text, "@user2")
        XCTAssertNil(linkResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult2.range), "@user2")
    }
    
    func testLinkResultsForHashtagsWithoutEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing #tag1 @and #tag2 @user # @ @@user @#tag without emojis"
        
        let linkResults = contextLabel.linkResultsForHashtags(inString: contextLabel.text)
        
        XCTAssertEqual(linkResults.count, 2)
        
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "#tag1")
        XCTAssertNil(linkResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult1.range), "#tag1")
        
        let linkResult2 = linkResults[1]
        XCTAssertEqual(linkResult2.text, "#tag2")
        XCTAssertNil(linkResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult2.range), "#tag2")
    }

    func testLinkResultsForHashtagsWithEmojis() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Testing ☕️🍪 #tag1 ☕️🍪 @and #tag2😊 @user #tag3☕️emoji # @ @@user @#tag with emojis 👍"
        
        let linkResults = contextLabel.linkResultsForHashtags(inString: contextLabel.text)
        
        XCTAssertEqual(linkResults.count, 3)
        
        let linkResult1 = linkResults[0]
        XCTAssertEqual(linkResult1.text, "#tag1")
        XCTAssertNil(linkResult1.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult1.range), "#tag1")
        
        let linkResult2 = linkResults[1]
        XCTAssertEqual(linkResult2.text, "#tag2")
        XCTAssertNil(linkResult2.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult2.range), "#tag2")
        
        let linkResult3 = linkResults[2]
        XCTAssertEqual(linkResult3.text, "#tag3")
        XCTAssertNil(linkResult3.textLink)
        XCTAssertEqual(NSString(string: contextLabel.text).substring(with: linkResult3.range), "#tag3")
    }
    
    func testLinkResultsForTextLinksWithMultipleOccuranciesWithoutRange() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "one two three one two three one two one"
        
        let oneTextLink = TextLink(text: "one", range: nil) { }
        let twoTextLink = TextLink(text: "two", range: nil) { }
        let threeTextLink = TextLink(text: "three", range: nil) { }
        
        let oneLinkResults = contextLabel.linkResultsForTextLinks([oneTextLink])
        let twoLinkResults = contextLabel.linkResultsForTextLinks([twoTextLink])
        let threeLinkResults = contextLabel.linkResultsForTextLinks([threeTextLink])
        let linkResults = contextLabel.linkResultsForTextLinks([oneTextLink, twoTextLink, threeTextLink])
        
        XCTAssertEqual(oneLinkResults.count, 4)
        XCTAssertEqual(twoLinkResults.count, 3)
        XCTAssertEqual(threeLinkResults.count, 2)
        XCTAssertEqual(linkResults.count, 4+3+2)
    }
    
    func testLinkResultsForTextLinksWithMultipleOccuranciesWithRange() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "one two three one two three one two one"
        
        let range = NSMakeRange(0, "one two three on".count)
        
        let oneTextLink = TextLink(text: "one", range: range) { }
        let twoTextLink = TextLink(text: "two", range: range) { }
        let threeTextLink = TextLink(text: "three", range: range) { }
        
        let oneLinkResults = contextLabel.linkResultsForTextLinks([oneTextLink])
        let twoLinkResults = contextLabel.linkResultsForTextLinks([twoTextLink])
        let threeLinkResults = contextLabel.linkResultsForTextLinks([threeTextLink])
        let linkResults = contextLabel.linkResultsForTextLinks([oneTextLink, twoTextLink, threeTextLink])
        
        XCTAssertEqual(oneLinkResults.count, 1)
        XCTAssertEqual(twoLinkResults.count, 1)
        XCTAssertEqual(threeLinkResults.count, 1)
        XCTAssertEqual(linkResults.count, 1+1+1)
    }
    
    func testEmailDetectionInText() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Text with test@gmail.com email"
        
        let linkResults = contextLabel.contextLabelData!.linkResults
        XCTAssertEqual(linkResults.count, 1)
        XCTAssertEqual(linkResults[0].detectionType, .email)
        XCTAssertEqual(linkResults[0].text, "test@gmail.com")
    }
    
    func testEmailDetectionInTextWhenNotAllowed() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.linkDetectionTypes = [.userHandle, .hashtag, .url, .textLink]
        contextLabel.text = "Text with test@gmail.com email"
        
        let linkResults = contextLabel.contextLabelData!.linkResults
        XCTAssertEqual(linkResults.count, 0)
    }
    
    func testPhoneNumbersDetectionInText() {
        let contextLabel = ContextLabel(frame: CGRect.zero)
        contextLabel.text = "Text with 1-541-754-3010 and (541) 754-3010 and +1-541-754-3010 and +420608123456"
        
        let linkResults = contextLabel.contextLabelData!.linkResults
        XCTAssertEqual(linkResults.count, 4)
        
        XCTAssertEqual(linkResults[0].detectionType, .phoneNumber)
        XCTAssertEqual(linkResults[0].text, "1-541-754-3010")
        
        XCTAssertEqual(linkResults[1].detectionType, .phoneNumber)
        XCTAssertEqual(linkResults[1].text, "(541) 754-3010")
        
        XCTAssertEqual(linkResults[2].detectionType, .phoneNumber)
        XCTAssertEqual(linkResults[2].text, "+1-541-754-3010")
        
        XCTAssertEqual(linkResults[3].detectionType, .phoneNumber)
        XCTAssertEqual(linkResults[3].text, "+420608123456")
    }
     
}

//
//  ContextLabel.swift
//  ContextLabel
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//

import Foundation
import UIKit

protocol ContextLabelDelegate {
    func contextLabel(contextLabel: ContextLabel, didSelectText: String, inRange: NSRange)
}

class ContextLabel: UILabel, NSLayoutManagerDelegate {
    
    struct LinkDetectionType : RawOptionSetType, BooleanType {
        private var value: UInt = 0
        init(_ value: UInt) { self.value = value }
        var boolValue: Bool { return self.value != 0 }
        func toRaw() -> UInt { return self.value }
        static var allZeros: LinkDetectionType { return self(0) }
        static func fromRaw(raw: UInt) -> LinkDetectionType? { return self(raw) }
        static func fromMask(raw: UInt) -> LinkDetectionType { return self(raw) }
        static func convertFromNilLiteral() -> LinkDetectionType { return self(0) }
        
        static var None: LinkDetectionType { return self(0) }
        static var UserHandle: LinkDetectionType { return LinkDetectionType(1 << 0) }
        static var Hashtag: LinkDetectionType { return LinkDetectionType(1 << 1) }
        static var URL: LinkDetectionType { return LinkDetectionType(1 << 2) }
    }
    
    struct LinkRangeResult {
        var linkDetectionType: LinkDetectionType
        var linkRange: NSRange
        var linkString: String
    }
    
    // Delegate
    var delegate: ContextLabelDelegate?
    
    // TextColors
    lazy var userHandleTextColor: UIColor = {
        let _userHandleTextColor = UIColor(red: 71.0/255.0, green: 90.0/255.0, blue: 109.0/255.0, alpha: 1.0)
        return _userHandleTextColor
        }()

    lazy var hashtagTextColor: UIColor = {
        let _hashtagTextColor = UIColor(red: 151.0/255.0, green: 154.0/255.0, blue: 158.0/255.0, alpha: 1.0)
        return _hashtagTextColor
        }()

    lazy var linkTextColor: UIColor = {
        let _linkTextColor = UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        return _linkTextColor
        }()
    
    var userHandleHighlightedTextColor: UIColor?
    var hashtagHighlightedTextColor: UIColor?
    var linkHighlightedTextColor: UIColor?
    
    private var privateUserHandleHighlightedTextColor: UIColor {
        get {
            if let userHandleHighlightedTextColor = userHandleHighlightedTextColor {
                return userHandleHighlightedTextColor
            } else {
                return highlightedTextColorForTextColor(userHandleTextColor)
            }
        }
    }

    private var privateHashtagHighlightedTextColor: UIColor {
        if let hashtagHighlightedTextColor = hashtagHighlightedTextColor {
            return hashtagHighlightedTextColor
        } else {
            return highlightedTextColorForTextColor(hashtagTextColor)
        }
    }

    private var privateLinkHighlightedTextColor: UIColor {
        if let linkHighlightedTextColor = linkHighlightedTextColor {
            return linkHighlightedTextColor
        } else {
            return highlightedTextColorForTextColor(linkTextColor)
        }
    }

    // Automatic detection of links, hashtags and usernames. When this is enabled links
    // are coloured using the textColor property above
    var automaticLinkDetectionEnabled: Bool = true {
        didSet {
            updateTextStoreWithText()
        }
    }
    
    // linkDetectionTypes
    var linkDetectionTypes: LinkDetectionType = .UserHandle | .Hashtag | .URL {
        didSet {
            updateTextStoreWithText()
        }
    }
    
    // Selected linkRangeResult
    var selectedLinkRangeResult: LinkRangeResult?
    
    // Dictionary of detected links and their ranges in the text
    var linkRangeResults: [LinkRangeResult]?
    
    // Specifies the space in which to render text
    lazy var textContainer: NSTextContainer = {
        let _textContainer = NSTextContainer()
        _textContainer.lineFragmentPadding = 0;
        _textContainer.maximumNumberOfLines = self.numberOfLines;
        _textContainer.lineBreakMode = self.lineBreakMode;
        _textContainer.size = self.bounds.size;
        
        return _textContainer
        }()
    
    // Used to control layout of glyphs and rendering
    lazy var layoutManager: NSLayoutManager = {
        let _layoutManager = NSLayoutManager()
        _layoutManager.delegate = self
        _layoutManager.addTextContainer(self.textContainer)
        
        return _layoutManager
        }()
    
    // Backing storage for text that is rendered by the layout manager
    lazy var textStorage: NSTextStorage? = {
        let _textStorage = NSTextStorage()
        _textStorage.addLayoutManager(self.layoutManager)
        
        return _textStorage
        }()
    
    // MARK: Properties override

    override var frame: CGRect {
        didSet {
            textContainer.size = bounds.size;
        }
    }

    override var bounds: CGRect {
        didSet {
            textContainer.size = bounds.size
        }
    }
    
    // MARK : Initializations
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupTextSystem()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextSystem()
    }

    override convenience init() {
        self.init(frame:CGRectZero)
    }
    
    convenience init(with userHandleTextColor: UIColor, hashtagTextColor: UIColor, linkTextColor: UIColor) {
        self.init(frame:CGRectZero)
        
        self.userHandleTextColor = userHandleTextColor
        self.hashtagTextColor = hashtagTextColor
        self.linkTextColor = linkTextColor
    }
    
    // MARK : Override Functions
    
    override var text: String! {
        didSet {
            updateTextStoreWithText()
        }
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        
        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {
            selectedLinkRangeResult = linkRangeResult
        } else {
            selectedLinkRangeResult = nil
        }

        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: true)
        
        super.touchesBegan(touches, withEvent: event)
    }

    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {

        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {
            
            if linkRangeResult.linkRange.location != selectedLinkRangeResult?.linkRange.location  {
                if let selectedLinkRangeResult = selectedLinkRangeResult {
                    addLinkAttributesToAttributedStringWithLinkRangeResults([selectedLinkRangeResult], highlighted: false)
                }
            }
            
            addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: true)
            
            selectedLinkRangeResult = linkRangeResult
        } else {
            if let selectedLinkRangeResult = selectedLinkRangeResult {
                addLinkAttributesToAttributedStringWithLinkRangeResults([selectedLinkRangeResult], highlighted: false)
            }
            
            selectedLinkRangeResult = nil
        }
        
        super.touchesMoved(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        
        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: false)
        
        // Call delegate
        if let selectedLinkRangeResult = selectedLinkRangeResult {
            delegate?.contextLabel(self, didSelectText: selectedLinkRangeResult.linkString, inRange: selectedLinkRangeResult.linkRange)
        }
        
        selectedLinkRangeResult = nil

        super.touchesEnded(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: false)
        
        super.touchesCancelled(touches, withEvent: event)
    }
    
    // MARK : Functions - Attribute Helpers
    
    func attributesFromProperties() -> [NSObject : AnyObject] {
        
        // Shadow attributes
        let shadow = NSShadow()
        if self.shadowColor != nil {
            shadow.shadowColor = self.shadowColor
            shadow.shadowOffset = self.shadowOffset
        } else {
            shadow.shadowOffset = CGSizeMake(0, -1);
            shadow.shadowColor = nil;
        }
        
        // Color attributes
        var color = self.textColor
        if self.enabled == false {
            color = UIColor.lightGrayColor()
        } else if self.highlighted {
            color = self.highlightedTextColor
        }
        
        // Paragraph attributes
        var mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.alignment = self.textAlignment
        
        // Attributes dictionary
        let attributes = [NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: color,
            NSShadowAttributeName: shadow,
            NSParagraphStyleAttributeName: mutableParagraphStyle]
        
        return attributes
    }
    
    func attributesWithTextColor(textColor: UIColor) -> [NSObject: AnyObject] {
        
        var mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.alignment = self.textAlignment
        
        let attributes = [NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: mutableParagraphStyle]
        
        return attributes
    }
    
    // MARK : Functions
    
    func setupTextSystem() {

        // Attach the layou manager to the container and storage
        self.textContainer.layoutManager = self.layoutManager

        // Make sure user interaction is enabled so we can accept touches
        self.userInteractionEnabled = true

        // Establish the text store with our current text
        updateTextStoreWithText()
    }
    
    func updateTextStoreWithText() {
        var mutableAttributedString: NSMutableAttributedString?
        
        if text != nil {
            mutableAttributedString = NSMutableAttributedString(string: text!, attributes: attributesFromProperties())
        }
        
        if mutableAttributedString != nil {
            
            // Get link ranges
            linkRangeResults = getRangesForLinksInAttributedString(mutableAttributedString!)
            
            // Set attributedText
            attributedText = mutableAttributedString
            
            // Set the string on the storage
            textStorage?.setAttributedString(mutableAttributedString)
            
            // Addd attributes to link ranges
            if let linkRangeResults = linkRangeResults {
                addLinkAttributesToAttributedStringWithLinkRangeResults(linkRangeResults)
            }
        }
    }
    
    // Returns array of ranges for all special words, user handles, hashtags and urls
    func getRangesForLinksInAttributedString(attributedString: NSAttributedString) -> [LinkRangeResult] {
        var rangesForLinks = [LinkRangeResult]()

        if linkDetectionTypes & .UserHandle {
            rangesForLinks += getRangesForUserHandles(attributedString.string)
        }

        if linkDetectionTypes & .Hashtag {
            rangesForLinks += getRangesForHashtags(attributedString.string)
        }

        if linkDetectionTypes & .URL {
            rangesForLinks += getRangesForURLs(attributedString)
        }

        return rangesForLinks
    }

    func getRangesForUserHandles(text: String) -> [LinkRangeResult] {
        let rangesForUserHandles = getRangesForLinkType(LinkDetectionType.UserHandle, regexPattern: "(?<!\\w)@([\\w\\_]+)?", text: text)
        return rangesForUserHandles
    }

    func getRangesForHashtags(text: String) -> [LinkRangeResult] {
        let rangesForHashtags = getRangesForLinkType(LinkDetectionType.Hashtag, regexPattern: "(?<!\\w)#([\\w\\_]+)?", text: text)
        return rangesForHashtags
    }

    func getRangesForLinkType(linkType: LinkDetectionType, regexPattern: String, text: String) -> [LinkRangeResult] {
        var rangesForLinkType = [LinkRangeResult]()

        // Setup a regular expression for user handles and hashtags
        var error: NSError?
        let regex = NSRegularExpression(pattern: regexPattern, options: .CaseInsensitive, error: &error)

        // Run the expression and get matches
        let length: Int = countElements(text)
        let matches = regex.matchesInString(text, options: .ReportCompletion, range: NSMakeRange(0, length))

        // Add all our ranges to the result
        for match in matches {
            if let textCheckingResult = match as? NSTextCheckingResult {
                let matchRange = textCheckingResult.range
                let swiftRange = advance(text.startIndex, matchRange.location)..<advance(text.startIndex, matchRange.location + matchRange.length)
                let matchString = text.substringWithRange(swiftRange)
                
                rangesForLinkType.append(LinkRangeResult(linkDetectionType: linkType, linkRange: matchRange, linkString: matchString))
            }
        }

        return rangesForLinkType
    }

    func getRangesForURLs(attributedString: NSAttributedString) -> [LinkRangeResult] {
        var rangesForURLs = [LinkRangeResult]()

        // Use a data detector to find urls in the text
        let plainText = attributedString.string
        var error: NSError?
        if let dataDetector = NSDataDetector.dataDetectorWithTypes(NSTextCheckingType.Link.toRaw(), error: &error) {
            let matches = dataDetector.matchesInString(plainText, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, countElements(plainText)))

            // Add a range entry for every url we found
            for match in matches {
                if let textCheckingResult = match as? NSTextCheckingResult {
                    let matchRange = textCheckingResult.range

                    // If there's a link embedded in the attributes, use that instead of the raw text
                    var realURL: AnyObject? = attributedString.attribute(NSLinkAttributeName, atIndex: matchRange.location, effectiveRange: nil)
                    if realURL == nil {
                        realURL = plainText.substringWithRange(advance(text.startIndex, matchRange.location)..<advance(text.startIndex, matchRange.location + matchRange.length))
                    }

                    if textCheckingResult.resultType == .Link {
                        if let matchString = realURL as? String {
                            rangesForURLs.append(LinkRangeResult(linkDetectionType: LinkDetectionType.URL, linkRange: matchRange, linkString: matchString))
                        }
                    }
                }
            }
        }

        return rangesForURLs
    }
    
    func addLinkAttributesToAttributedStringWithLinkRangeResults(linkRangeResults: [LinkRangeResult], highlighted: Bool = false) {
        var attributedString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributedText)

        for linkRangeResult in linkRangeResults {
            var attributes: [NSObject: AnyObject]?
            
            if linkRangeResult.linkDetectionType & .UserHandle {
                let color = highlighted ? privateUserHandleHighlightedTextColor : userHandleTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if linkRangeResult.linkDetectionType & .Hashtag {
                let color = highlighted ? privateHashtagHighlightedTextColor : hashtagTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if linkRangeResult.linkDetectionType & .URL {
                let color = highlighted ? privateLinkHighlightedTextColor : linkTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if attributes != nil {
                attributedString.addAttributes(attributes!, range: linkRangeResult.linkRange)
            }
        }
        
        attributedText = attributedString
        
    }
    
    func addLinkAttributesToLinkRangeResultWithTouches(touches: NSSet!, highlighted: Bool) {
        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {
            addLinkAttributesToAttributedStringWithLinkRangeResults([linkRangeResult], highlighted: highlighted)
        }
    }
    
    func getLinkRangeResultWithTouches(touches: NSSet!) -> LinkRangeResult? {
        let touchLocation = touches.anyObject().locationInView(self)
        if let touchedLink = getLinkRangeResultAtLocation(touchLocation) {
            return touchedLink
        }
        
        return nil
    }
    
    func getLinkRangeResultAtLocation(location: CGPoint) -> LinkRangeResult? {
        
        var test: CGFloat = 0.0
        let characterIndex = layoutManager.characterIndexForPoint(location, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: &test)
        
        if characterIndex <= textStorage?.length {
            if let linkRangeResults = linkRangeResults {
                for linkRangeResult in linkRangeResults {
                    if linkRangeResult.linkRange.location <= characterIndex &&
                        linkRangeResult.linkRange.location + linkRangeResult.linkRange.length >= characterIndex {
                            return linkRangeResult
                    }
                }
            }
        }
        
        return nil
    }
    
    func highlightedTextColorForTextColor(textColor: UIColor) -> UIColor {
        return textColor.colorWithAlphaComponent(0.5)
    }
}
//
//  ContextLabel.swift
//  ContextLabel
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//
//
// Fixed by DeMoN, using info from: http://stackoverflow.com/questions/27880650/swift-extract-regex-matches
//

import Foundation
import UIKit

extension String {
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = advance(utf16.startIndex, nsRange.location, utf16.endIndex)
        let to16 = advance(from16, nsRange.length, utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    func NSRangeFromRange(range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(from - utf16view.startIndex, to - from)
    }
}

protocol ContextLabelDelegate {
    func contextLabel(contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult)
    func contextLabel(contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult)
    func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult)
}

public class ContextLabelData: NSObject {
    var attributedString: NSAttributedString
    var linkRangeResults: Array<LinkRangeResult>
    var userInfo: Dictionary<NSObject, AnyObject>?
    
    // MARK: Initializers
    
    init(attributedString: NSAttributedString, linkRangeResults: [LinkRangeResult]) {
        self.attributedString = attributedString
        self.linkRangeResults = linkRangeResults
        super.init()
    }
}

public class LinkRangeResult: NSObject {
    var linkDetectionType: ContextLabel.LinkDetectionType
    var linkRange: Range<String.Index>
    var linkNSRange: NSRange
    var linkString: String
    var textLink: ContextLabel.TextLink?
    
    // MARK: Initializers
    
    init(linkDetectionType: ContextLabel.LinkDetectionType, linkRange: Range<String.Index>, linkNSRange: NSRange, linkString: String, textLink: ContextLabel.TextLink?) {
        self.linkDetectionType = linkDetectionType
        self.linkRange = linkRange
        self.linkNSRange = linkNSRange
        self.linkString = linkString
        self.textLink = textLink
        
        super.init()
    }
}

public class ContextLabel: UILabel, NSLayoutManagerDelegate {
    
    struct LinkDetectionType : RawOptionSetType {
        typealias RawValue = UInt
        private var value: UInt = 0
        init(_ value: UInt) { self.value = value }
        init(rawValue value: UInt) { self.value = value }
        init(nilLiteral: ()) { self.value = 0 }
        static var allZeros: LinkDetectionType { return self(0) }
        static func fromMask(raw: UInt) -> LinkDetectionType { return self(raw) }
        var rawValue: UInt { return self.value }
        
        static var None: LinkDetectionType { return self(0) }
        static var UserHandle: LinkDetectionType { return LinkDetectionType(1 << 0) }
        static var Hashtag: LinkDetectionType { return LinkDetectionType(1 << 1) }
        static var URL: LinkDetectionType { return LinkDetectionType(1 << 2) }
        static var TextLink: LinkDetectionType { return LinkDetectionType(1 << 3) }
    }
    
    public struct TextLink {
        var text: String
        var action: ()->()
    }
    
    // Delegate
    var delegate: ContextLabelDelegate?
    
    
    // MARK: Config Properties
    
    // LineSpacing
    var lineSpacing: CGFloat?
    
    // TextColors
    lazy var textLinkTextColor: UIColor = {
        let _textLinkTextColor = UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        return _textLinkTextColor
        }()
    
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
    
    var textLinkHighlightedTextColor: UIColor?
    var userHandleHighlightedTextColor: UIColor?
    var hashtagHighlightedTextColor: UIColor?
    var linkHighlightedTextColor: UIColor?
    
    // MARK: Private Properties
    
    private var privateTextLinkHighlightedTextColor: UIColor {
        get {
            if let textLinkHighlightedTextColor = textLinkHighlightedTextColor {
                return textLinkHighlightedTextColor
            } else {
                return highlightedTextColorForTextColor(textLinkTextColor)
            }
        }
    }
    
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

    
    // MARK: Properties
    
    // Automatic detection of links, hashtags and usernames. When this is enabled links
    // are coloured using the textColor property above
    var automaticLinkDetectionEnabled: Bool = true {
        didSet {
            setContextLabelDataWithText(nil)
        }
    }
    
    // linkDetectionTypes
    var linkDetectionTypes: LinkDetectionType = .UserHandle | .Hashtag | .URL | .TextLink {
        didSet {
            setContextLabelDataWithText(nil)
        }
    }
    
    // Array of link texts
    var textLinks: [TextLink]? {
        didSet {
            if let textLinks = textLinks {
                if let contextLabelData = contextLabelData {
                    
                    // Add linkRangeResults for textLinks
                    let textLinkRangeResults = getRangesForTextLinks(textLinks)
                    contextLabelData.linkRangeResults += textLinkRangeResults
                    
                    // Addd attributes for textLinkRangeResults
                    let attributedString = addLinkAttributesToAttributedString(contextLabelData.attributedString, withLinkRangeResults: textLinkRangeResults)
                    contextLabelData.attributedString = attributedString
                    
                    // Set attributedText
                    attributedText = contextLabelData.attributedString
                }
            }
        }
    }
    
    // Selected linkRangeResult
    private var selectedLinkRangeResult: LinkRangeResult?
    
    // Cachable Object to encapsulate all relevant data to restore ContextLabel values
    var contextLabelData: ContextLabelData? {
        didSet {
            if let contextLabelData = contextLabelData {
                // Set attributedText
                attributedText = contextLabelData.attributedString
                
                // Set the string on the storage
                textStorage?.setAttributedString(contextLabelData.attributedString)
            }
        }
    }
    
    // Specifies the space in which to render text
    lazy var textContainer: NSTextContainer = {
        let _textContainer = NSTextContainer()
        _textContainer.lineFragmentPadding = 0
        _textContainer.maximumNumberOfLines = self.numberOfLines
        _textContainer.lineBreakMode = self.lineBreakMode
        _textContainer.size = CGSizeMake(CGRectGetWidth(self.bounds), CGFloat.max)
        
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

    public override var frame: CGRect {
        didSet {
            textContainer.size = CGSizeMake(CGRectGetWidth(self.bounds), CGFloat.max)
        }
    }

    public override var bounds: CGRect {
        didSet {
            textContainer.size = CGSizeMake(CGRectGetWidth(self.bounds), CGFloat.max)
        }
    }
    
    public override var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
        }
    }
    
    public override var text: String! {
        didSet {
            setContextLabelDataWithText(text)
        }
    }
    
    
    // MARK : Initializations
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupTextSystem()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextSystem()
    }

//    public override convenience init() {
//        self.init(frame:CGRectZero)
//    }
    
    public convenience init(with userHandleTextColor: UIColor, hashtagTextColor: UIColor, linkTextColor: UIColor) {
        self.init(frame:CGRectZero)
        
        self.userHandleTextColor = userHandleTextColor
        self.hashtagTextColor = hashtagTextColor
        self.linkTextColor = linkTextColor
    }
    
    
    // MARK : Override Functions
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        textContainer.size = CGSizeMake(CGRectGetWidth(self.bounds), CGFloat.max)
    }
    
    public override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {

            selectedLinkRangeResult = linkRangeResult

            // Call delegate
            if let selectedLinkRangeResult = selectedLinkRangeResult {
                delegate?.contextLabel(self, beganTouchOf: selectedLinkRangeResult.linkString, with: selectedLinkRangeResult)
            }
            
        } else {
            selectedLinkRangeResult = nil
        }

        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: true)
        
        super.touchesBegan(touches, withEvent: event)
    }

    public override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {

        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {
            
            if linkRangeResult.linkRange.startIndex != selectedLinkRangeResult?.linkRange.startIndex  {
                if let selectedLinkRangeResult = selectedLinkRangeResult {
                    attributedText = addLinkAttributesToAttributedString(attributedText, withLinkRangeResults: [selectedLinkRangeResult], highlighted: false)
                }
            }
            
            addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: true)
            
            selectedLinkRangeResult = linkRangeResult
            
            // Call delegate
            if let selectedLinkRangeResult = selectedLinkRangeResult {
                delegate?.contextLabel(self, movedTouchTo: selectedLinkRangeResult.linkString, with: selectedLinkRangeResult)
            }
            
        } else {
            if let selectedLinkRangeResult = selectedLinkRangeResult {
                attributedText = addLinkAttributesToAttributedString(attributedText, withLinkRangeResults: [selectedLinkRangeResult], highlighted: false)
            }
            
            selectedLinkRangeResult = nil
        }
        
        super.touchesMoved(touches, withEvent: event)
    }
    
    public override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: false)
        
        // Call delegate
        if let selectedLinkRangeResult = selectedLinkRangeResult {
            delegate?.contextLabel(self, endedTouchOf: selectedLinkRangeResult.linkString, with: selectedLinkRangeResult)
            selectedLinkRangeResult.textLink?.action()
        }
        
        selectedLinkRangeResult = nil

        super.touchesEnded(touches, withEvent: event)
    }
    
    public override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent!) {
        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: false)
        super.touchesCancelled(touches, withEvent: event)
    }
    
    // MARK: Functions
    
    func addAttributes(attributes: Dictionary<NSObject, AnyObject>, range: NSRange) {
        if let contextLabelData = contextLabelData {
            var mutableAttributedString = NSMutableAttributedString(attributedString: contextLabelData.attributedString)
            mutableAttributedString.addAttributes(attributes, range: range)
            
            contextLabelData.attributedString = mutableAttributedString
            attributedText = contextLabelData.attributedString
        }
    }
    
    public func setContextLabelDataWithText(text: String?) {
        var text = text
        
        if text == nil {
            text = self.text
        }
        
        if let text = text {
            self.contextLabelData = contextLabelDataWithText(text)
        }
    }
    
    public func contextLabelDataWithText(text: String?) -> ContextLabelData? {
        if let text = text {
            var mutableAttributedString = NSMutableAttributedString(string: text, attributes: attributesFromProperties())
            var linkRangeResults = getRangesForLinksInAttributedString(mutableAttributedString)
            
            // Addd attributes to link ranges
            let attributedString = addLinkAttributesToAttributedString(mutableAttributedString, withLinkRangeResults: linkRangeResults)
            
            return ContextLabelData(attributedString: attributedString, linkRangeResults: linkRangeResults)
        }
        
        return nil
    }
    
    public func setText(text:String, withTextLinks textLinks: [TextLink]) {
        self.textLinks = textLinks
        
        self.contextLabelData = contextLabelDataWithText(text)
    }
    
    // TEST testAttributesFromProperties()
    public func attributesFromProperties() -> [NSObject : AnyObject] {
        
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
            if self.highlightedTextColor != nil {
                color = self.highlightedTextColor!
            }
        }
        
        // Paragraph attributes
        var mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.alignment = self.textAlignment
        
        // LineSpacing
        if let lineSpacing = lineSpacing {
            mutableParagraphStyle.lineSpacing = lineSpacing
        }
        
        // Attributes dictionary
        let attributes = [NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: color,
            NSShadowAttributeName: shadow,
            NSParagraphStyleAttributeName: mutableParagraphStyle]
        
        return attributes
    }
    
    private func attributesWithTextColor(textColor: UIColor) -> [NSObject: AnyObject] {
        var attributes = attributesFromProperties()
        attributes[NSForegroundColorAttributeName] = textColor
        
        return attributes
    }
    
    private func setupTextSystem() {

        // Attach the layou manager to the container and storage
        self.textContainer.layoutManager = self.layoutManager

        // Make sure user interaction is enabled so we can accept touches
        self.userInteractionEnabled = true

        // Establish the text store with our current text
        setContextLabelDataWithText(nil)
    }
    
    // Returns array of ranges for all special words, user handles, hashtags and urls
    private func getRangesForLinksInAttributedString(attributedString: NSAttributedString) -> [LinkRangeResult] {
        var rangesForLinks = [LinkRangeResult]()

        if let textLinks = textLinks {
            if textLinks.count > 0 {
                rangesForLinks += getRangesForTextLinks(textLinks)
            }
        }
        
        if linkDetectionTypes & .UserHandle != nil {
            rangesForLinks += getRangesForUserHandlesInText(attributedString.string)
        }

        if linkDetectionTypes & .Hashtag != nil {
            rangesForLinks += getRangesForHashtagsInText(attributedString.string)
        }

        if linkDetectionTypes & .URL != nil {
            rangesForLinks += getRangesForURLsInAttributedString(attributedString)
        }

        return rangesForLinks
    }

    private func getRangesForTextLinks(textLinks: [TextLink]) -> [LinkRangeResult] {
        var rangesForLinkType = [LinkRangeResult]()
        
        for textLink in textLinks {
            let linkType = LinkDetectionType.TextLink
            let matchString = textLink.text
            if let stringIndexRange = text.rangeOfString(textLink.text, options: .CaseInsensitiveSearch) {
                let nsRange = textLink.text.NSRangeFromRange(stringIndexRange)
                rangesForLinkType.append(LinkRangeResult(linkDetectionType: linkType, linkRange: stringIndexRange, linkNSRange: nsRange, linkString: matchString, textLink: textLink))
            }
        }
        
        return rangesForLinkType
    }
    
    private func getRangesForUserHandlesInText(text: String) -> [LinkRangeResult] {
        let rangesForUserHandles = getRangesForLinkType(LinkDetectionType.UserHandle, regexPattern: "(?<!\\w)@([\\w\\_.]+)?", text: text)
        return rangesForUserHandles
    }

    private func getRangesForHashtagsInText(text: String) -> [LinkRangeResult] {
        let rangesForHashtags = getRangesForLinkType(LinkDetectionType.Hashtag, regexPattern: "(?<!\\w)#([\\w\\_]+)?", text: text)
        return rangesForHashtags
    }

    private func getRangesForLinkType(linkType: LinkDetectionType, regexPattern: String, text: String) -> [LinkRangeResult] {
        var rangesForLinkType = [LinkRangeResult]()

        // Setup a regular expression for user handles and hashtags
        var error: NSError?
        let regex = NSRegularExpression(pattern: regexPattern, options: .CaseInsensitive, error: &error)

        // Run the expression and get matches
        if let matches = regex?.matchesInString(text, options: .ReportCompletion, range: NSMakeRange(0, count(text.utf16))) {

            // Add all our ranges to the result
            for match in matches {
                if let textCheckingResult = match as? NSTextCheckingResult {
                    let matchRange = textCheckingResult.range
                    let stringIndexRange = text.rangeFromNSRange(matchRange)
                    let matchString = text.substringWithRange(stringIndexRange!)
                    
                    rangesForLinkType.append(LinkRangeResult(linkDetectionType: linkType, linkRange: stringIndexRange!, linkNSRange: matchRange, linkString: matchString, textLink: nil))
                }
            }
        }

        return rangesForLinkType
    }

    private func getRangesForURLsInAttributedString(attributedString: NSAttributedString) -> [LinkRangeResult] {
        var rangesForURLs = [LinkRangeResult]()

        // Use a data detector to find urls in the text
        let plainText = attributedString.string
        var error: NSError?
        if let dataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue, error: &error) {
            let matches = dataDetector.matchesInString(plainText, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, count(plainText)))

            // Add a range entry for every url we found
            for match in matches {
                if let textCheckingResult = match as? NSTextCheckingResult {
                    let matchRange = textCheckingResult.range
                    let stringIndexRange = text.rangeFromNSRange(matchRange)
                    // If there's a link embedded in the attributes, use that instead of the raw text
                    var realURL: AnyObject? = attributedString.attribute(NSLinkAttributeName, atIndex: matchRange.location, effectiveRange: nil)
                    if realURL == nil {
                        realURL = plainText.substringWithRange(stringIndexRange!)
                    }

                    if textCheckingResult.resultType == .Link {
                        if let matchString = realURL as? String {
                            rangesForURLs.append(LinkRangeResult(linkDetectionType: LinkDetectionType.URL, linkRange: stringIndexRange!, linkNSRange: matchRange, linkString: matchString, textLink: nil))
                        }
                    }
                }
            }
        }

        return rangesForURLs
    }
    
    private func addLinkAttributesToAttributedString(attributedString: NSAttributedString, withLinkRangeResults linkRangeResults: [LinkRangeResult], highlighted: Bool = false) -> NSAttributedString {
        var mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        for linkRangeResult in linkRangeResults {
            var attributes: [NSObject: AnyObject]?
            
            if linkRangeResult.linkDetectionType == .TextLink {
                let color = highlighted ? privateTextLinkHighlightedTextColor : textLinkTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if linkRangeResult.linkDetectionType == .UserHandle {
                let color = highlighted ? privateUserHandleHighlightedTextColor : userHandleTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if linkRangeResult.linkDetectionType == .Hashtag {
                let color = highlighted ? privateHashtagHighlightedTextColor : hashtagTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if linkRangeResult.linkDetectionType == .URL {
                let color = highlighted ? privateLinkHighlightedTextColor : linkTextColor
                attributes = attributesWithTextColor(color)
            }
            
            if attributes != nil {
                mutableAttributedString.setAttributes(attributes!, range: linkRangeResult.linkNSRange)
            }
        }
        
        return mutableAttributedString
    }
    
    private func addLinkAttributesToLinkRangeResultWithTouches(touches: NSSet!, highlighted: Bool) {
        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {
            attributedText = addLinkAttributesToAttributedString(attributedText, withLinkRangeResults: [linkRangeResult], highlighted: highlighted)
        }
    }
    
    private func getLinkRangeResultWithTouches(touches: NSSet!) -> LinkRangeResult? {
        let anyTouch: UITouch = touches.anyObject() as! UITouch
        let touchLocation = anyTouch.locationInView(self)
        if let touchedLink = getLinkRangeResultAtLocation(touchLocation) {
            return touchedLink
        }
        
        return nil
    }
    
    private func getLinkRangeResultAtLocation(location: CGPoint) -> LinkRangeResult? {
        var fractionOfDistance: CGFloat = 0.0
        let characterIndex = layoutManager.characterIndexForPoint(location, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: &fractionOfDistance)
        
        if characterIndex <= textStorage?.length {
            if let linkRangeResults = contextLabelData?.linkRangeResults {
                for linkRangeResult in linkRangeResults {
                    let linkRange = linkRangeResult.linkNSRange
                    if linkRange.location <= characterIndex &&
                        (linkRange.location + linkRange.length - 1) >= characterIndex {
                            
                            let glyphRange = layoutManager.glyphRangeForCharacterRange(linkRange, actualCharacterRange: nil)
                            let boundingRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
                            
                            if CGRectContainsPoint(boundingRect, location) {
                                return linkRangeResult
                            }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func highlightedTextColorForTextColor(textColor: UIColor) -> UIColor {
        return textColor.colorWithAlphaComponent(0.5)
    }
}

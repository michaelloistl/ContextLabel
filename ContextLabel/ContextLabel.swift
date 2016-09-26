//
//  ContextLabel.swift
//  ContextLabel
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//

import Foundation
import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

//public protocol ContextLabelDelegate {
//    func contextLabel(_ contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult)
//    func contextLabel(_ contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult)
//    func contextLabel(_ contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult)
//
//    func contextLabel(_ contextLabel: ContextLabel, textLinkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
//    func contextLabel(_ contextLabel: ContextLabel, userHandleTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
//    func contextLabel(_ contextLabel: ContextLabel, hashtagTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
//    func contextLabel(_ contextLabel: ContextLabel, linkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
//}

//public extension ContextLabelDelegate {
//    
//    func contextLabel(_ contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult) {
//        
//    }
//    
//    func contextLabel(_ contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult) {
//        
//    }
//    
//    func contextLabel(_ contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult) {
//        
//    }
//
//    func contextLabel(_ contextLabel: ContextLabel, textLinkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
//        return nil
//    }
//    
//    func contextLabel(_ contextLabel: ContextLabel, userHandleTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
//        return nil
//    }
//    
//    func contextLabel(_ contextLabel: ContextLabel, hashtagTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
//        return nil
//    }
//    
//    func contextLabel(_ contextLabel: ContextLabel, linkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
//        return nil
//    }
//}

open class ContextLabelData: NSObject {
    var attributedString: NSAttributedString
    var linkResults: [LinkResult]
    var userInfo: [NSObject: AnyObject]?
    
    // MARK: Initializers
    
    init(attributedString: NSAttributedString, linkResults: [LinkResult]) {
        self.attributedString = attributedString
        self.linkResults = linkResults
        super.init()
    }
}

public struct LinkResult {
    public let detectionType: ContextLabel.LinkDetectionType
    public let range: NSRange
    public let text: String
    public let textLink: TextLink?
}

public struct TouchResult {
    public let linkResult: LinkResult
    public let touches: Set<UITouch>
    public let event: UIEvent?
    public let state: UIGestureRecognizerState
}


public struct TextLink {
    public let text: String
    public let range: NSRange?
    public let options: NSString.CompareOptions
    public let action: ()->()
        
    public init(text: String, range: NSRange? = nil, options: NSString.CompareOptions = [], action: @escaping ()->()) {
        self.text = text
        self.range = range
        self.options = options
        self.action = action
    }
}

open class ContextLabel: UILabel, NSLayoutManagerDelegate {
    
    public struct LinkDetectionType : OptionSet {
        public typealias RawValue = UInt
        fileprivate var value: UInt = 0
        init(_ value: UInt) { self.value = value }
        public init(rawValue value: UInt) { self.value = value }
        init(nilLiteral: ()) { self.value = 0 }
        static var allZeros: LinkDetectionType { return self.init(0) }
        static func fromMask(_ raw: UInt) -> LinkDetectionType { return self.init(raw) }
        public var rawValue: UInt { return self.value }
        
        static var None: LinkDetectionType { return self.init(0) }
        static var UserHandle: LinkDetectionType { return LinkDetectionType(1 << 0) }
        static var Hashtag: LinkDetectionType { return LinkDetectionType(1 << 1) }
        static var URL: LinkDetectionType { return LinkDetectionType(1 << 2) }
        static var TextLink: LinkDetectionType { return LinkDetectionType(1 << 3) }
    }
  
    let hashtagRegex = "(?<=\\s|^)#(\\w*[A-Za-z&_-]+\\w*)"
    let userHandleRegex = "(?<=\\s|^)@(\\w*[A-Za-z&_-]+\\w*)"
    
    // MARK: - Config Properties
    
    // LineSpacing
    public var lineSpacing: CGFloat?
    public var lineHeightMultiple: CGFloat?
    
    // TextColors
    
    public var textLinkTextColor: (LinkResult) -> (textColor: UIColor, highlightedTextColor: UIColor?) = { _ in
        return (UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0), nil)
    }
    
    public var userHandleTextColor: (LinkResult) -> (textColor: UIColor, highlightedTextColor: UIColor?) = { _ in
        return (UIColor(red: 71.0/255.0, green: 90.0/255.0, blue: 109.0/255.0, alpha: 1.0), nil)
    }
    
    public var hashtagTextColor: (LinkResult) -> (textColor: UIColor, highlightedTextColor: UIColor?) = { _ in
        return (UIColor(red: 151.0/255.0, green: 154.0/255.0, blue: 158.0/255.0, alpha: 1.0), nil)
    }
    
    public var linkTextColor: (LinkResult) -> (textColor: UIColor, highlightedTextColor: UIColor?) = { _ in
        return (UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0), nil)
    }
    
    // UnderlineStyle
    
    public var textLinkUnderlineStyle: (LinkResult) -> (NSUnderlineStyle) = { _ in
        return .styleNone
    }
    
    public var userHandleUnderlineStyle: (LinkResult) -> (NSUnderlineStyle) = { _ in
        return .styleNone
    }
    
    public var hashtagUnderlineStyle: (LinkResult) -> (NSUnderlineStyle) = { _ in
        return .styleNone
    }
    
    public var linkUnderlineStyle: (LinkResult) -> (NSUnderlineStyle) = { _ in
        return .styleNone
    }
    
    // Autolayout
    open var preferedHeight: CGFloat? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    open var preferedWidth: CGFloat? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Properties
    
    public var didTouch: (TouchResult) -> () = { _ in }
    
    // Automatic detection of links, hashtags and usernames. When this is enabled links
    // are coloured using the textColor property above
    public var automaticLinkDetectionEnabled: Bool = true {
        didSet {
            setContextLabelDataWithText(nil)
        }
    }
    
    // linkDetectionTypes
    public var linkDetectionTypes: LinkDetectionType = [.UserHandle, .Hashtag, .URL, .TextLink] {
        didSet {
            setContextLabelDataWithText(nil)
        }
    }
    
    // Array of link texts
    public var textLinks: [TextLink]? {
        didSet {
            if let textLinks = textLinks {
                if let contextLabelData = contextLabelData {
                    
                    // Add linkResults for textLinks
                    let linkResults = linkResultsForTextLinks(textLinks)
                    contextLabelData.linkResults += linkResults
                    
                    // Addd attributes for textLinkResults
                    let attributedString = addLinkAttributesTo(contextLabelData.attributedString, with: linkResults)
                    contextLabelData.attributedString = attributedString
                    
                    // Set attributedText
                    attributedText = contextLabelData.attributedString
                }
            }
        }
    }
    
    // Selected linkResult
    fileprivate var selectedLinkResult: LinkResult?
    
    // Cachable Object to encapsulate all relevant data to restore ContextLabel values
    public var contextLabelData: ContextLabelData? {
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
    fileprivate lazy var textContainer: NSTextContainer = {
        let _textContainer = NSTextContainer()
        _textContainer.lineFragmentPadding = 0
        _textContainer.maximumNumberOfLines = self.numberOfLines
        _textContainer.lineBreakMode = self.lineBreakMode
        _textContainer.size = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        
        return _textContainer
        }()
    
    // Used to control layout of glyphs and rendering
    fileprivate lazy var layoutManager: NSLayoutManager = {
        let _layoutManager = NSLayoutManager()
        _layoutManager.delegate = self
        _layoutManager.addTextContainer(self.textContainer)
        
        return _layoutManager
        }()
    
    // Backing storage for text that is rendered by the layout manager
    fileprivate lazy var textStorage: NSTextStorage? = {
        let _textStorage = NSTextStorage()
        _textStorage.addLayoutManager(self.layoutManager)
        
        return _textStorage
        }()
    
    
    // MARK: - Properties override

    open override var frame: CGRect {
        didSet {
            textContainer.size = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        }
    }

    open override var bounds: CGRect {
        didSet {
            textContainer.size = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        }
    }
    
    open override var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
        }
    }
    
    open override var text: String! {
        didSet {
            setContextLabelDataWithText(text)
        }
    }
    
    // MARK: - Initializations
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    public convenience init(frame: CGRect, didTouch: @escaping (TouchResult) -> ()) {
        self.init(frame: frame)
        
        self.didTouch = didTouch
        setup()
    }
    
    // MARK: - Override Methods
    
    open override var intrinsicContentSize : CGSize {
        var width = super.intrinsicContentSize.width
        var height = super.intrinsicContentSize.height
        
        if let preferedWidth = preferedWidth {
            width = preferedWidth
        }
        
        if let preferedHeight = preferedHeight {
            height = preferedHeight
        }
        
        return CGSize(width: width, height: height)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        textContainer.size = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let linkResult = linkResult(with: touches) {
            selectedLinkResult = linkResult
            didTouch(TouchResult(linkResult: linkResult, touches: touches, event: event, state: .began))
        } else {
            selectedLinkResult = nil
        }
        
        addLinkAttributesToLinkResult(withTouches: touches, highlighted: true)
        
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let linkResult = linkResult(with: touches) {
            if linkResult.range.location != selectedLinkResult?.range.location  {
                if let selectedLinkResult = selectedLinkResult, let attributedText = attributedText {
                    self.attributedText = addLinkAttributesTo(attributedText, with: [selectedLinkResult], highlighted: false)
                }
            }
            
            selectedLinkResult = linkResult
            
            addLinkAttributesToLinkResult(withTouches: touches, highlighted: true)
            
            didTouch(TouchResult(linkResult: linkResult, touches: touches, event: event, state: .changed))
        } else {
            if let selectedLinkResult = selectedLinkResult, let attributedText = attributedText {
                self.attributedText = addLinkAttributesTo(attributedText, with: [selectedLinkResult], highlighted: false)
            }
            selectedLinkResult = nil
        }
        
        super.touchesMoved(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        addLinkAttributesToLinkResult(withTouches: touches, highlighted: false)

        if let selectedLinkResult = selectedLinkResult {
            didTouch(TouchResult(linkResult: selectedLinkResult, touches: touches, event: event, state: .ended))
            selectedLinkResult.textLink?.action()
        }
        
        selectedLinkResult = nil
        
        super.touchesEnded(touches, with: event)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        addLinkAttributesToLinkResult(withTouches: touches, highlighted: false)
        
        super.touchesCancelled(touches, with: event)
    }
    
    // MARK: - Methods
    
    func addAttributes(_ attributes: Dictionary<String, AnyObject>, range: NSRange) {
        if let contextLabelData = contextLabelData {
            let mutableAttributedString = NSMutableAttributedString(attributedString: contextLabelData.attributedString)
            mutableAttributedString.addAttributes(attributes, range: range)
            
            contextLabelData.attributedString = mutableAttributedString
            attributedText = contextLabelData.attributedString
        }
    }
    
    open func setContextLabelDataWithText(_ text: String?) {
        var text = text
        
        if text == nil {
            text = self.text
        }
        
        if let text = text {
            self.contextLabelData = contextLabelDataWithText(text)
        }
    }
    
    open func contextLabelDataWithText(_ text: String?) -> ContextLabelData? {
        if let text = text {
            let mutableAttributedString = NSMutableAttributedString(string: text, attributes: attributesFromProperties())
            let _linkResults = linkResults(in: mutableAttributedString)
            let attributedString = addLinkAttributesTo(mutableAttributedString, with: _linkResults)

            return ContextLabelData(attributedString: attributedString, linkResults: _linkResults)
        }
        return nil
    }
    
    open func setText(_ text:String, withTextLinks textLinks: [TextLink]) {
        self.textLinks = textLinks
        
        self.contextLabelData = contextLabelDataWithText(text)
    }
    
    open func attributesFromProperties() -> [String : AnyObject] {
        
        // Shadow attributes
        let shadow = NSShadow()
        if self.shadowColor != nil {
            shadow.shadowColor = self.shadowColor
            shadow.shadowOffset = self.shadowOffset
        } else {
            shadow.shadowOffset = CGSize(width: 0, height: -1);
            shadow.shadowColor = nil;
        }
        
        // Color attributes
        var color = self.textColor
        if self.isEnabled == false {
            color = UIColor.lightGray
        } else if self.isHighlighted {
            if self.highlightedTextColor != nil {
                color = self.highlightedTextColor!
            }
        }
        
        // Paragraph attributes
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.alignment = self.textAlignment
        
        // LineSpacing
        if let lineSpacing = lineSpacing {
            mutableParagraphStyle.lineSpacing = lineSpacing
        }
        
        // LineHeightMultiple
        if let lineHeightMultiple = lineHeightMultiple {
            mutableParagraphStyle.lineHeightMultiple = lineHeightMultiple
        }
        
        // Attributes dictionary
        var attributes = [NSShadowAttributeName: shadow,
            NSParagraphStyleAttributeName: mutableParagraphStyle] as [String : Any]
        
        if let font = self.font {
            attributes[NSFontAttributeName] = font
        }
        
        if let color = color {
            attributes[NSForegroundColorAttributeName] = color
        }
        
        return attributes as [String : AnyObject]
    }
    
    fileprivate func attributesWithTextColor(_ textColor: UIColor) -> [String: AnyObject] {
        var attributes = attributesFromProperties()
        attributes[NSForegroundColorAttributeName] = textColor
        
        return attributes
    }
    
    fileprivate func attributesWithTextColor(_ textColor: UIColor, underlineStyle: NSUnderlineStyle) -> [String: AnyObject] {
        var attributes = attributesWithTextColor(textColor)
        attributes[NSUnderlineStyleAttributeName] = underlineStyle.rawValue as AnyObject?
        
        return attributes
    }
    
    fileprivate func setup() {
        lineBreakMode = .byTruncatingTail
        
        // Attach the layou manager to the container and storage
        self.textContainer.layoutManager = self.layoutManager

        // Make sure user interaction is enabled so we can accept touches
        self.isUserInteractionEnabled = true

        // Establish the text store with our current text
        setContextLabelDataWithText(nil)
    }
    
    // Returns array of link results for all special words, user handles, hashtags and urls
    fileprivate func linkResults(in attributedString: NSAttributedString) -> [LinkResult] {
        var linkResults = [LinkResult]()

        if let textLinks = textLinks {
            linkResults += linkResultsForTextLinks(textLinks)
        }
        
        if linkDetectionTypes.intersection(.UserHandle) != [] {
            linkResults += linkResultsForUserHandles(inString: attributedString.string)
        }

        if linkDetectionTypes.intersection(.Hashtag) != [] {
            linkResults += linkResultsForHashtags(inString: attributedString.string)
        }

        if linkDetectionTypes.intersection(.URL) != [] {
            linkResults += linkResultsForURLs(inAttributedString: attributedString)
        }

        return linkResults
    }

    // TEST: testLinkResultsForTextLinksWithoutEmojis()
    // TEST: testLinkResultsForTextLinksWithEmojis()
    // TEST: testLinkResultsForTextLinksWithMultipleOccuranciesWithoutRange()
    // TEST: testLinkResultsForTextLinksWithMultipleOccuranciesWithRange()
    internal func linkResultsForTextLinks(_ textLinks: [TextLink]) -> [LinkResult] {
        var linkResults = [LinkResult]()
        
        for textLink in textLinks {
            let linkType = LinkDetectionType.TextLink
            let matchString = textLink.text
            
            let range = textLink.range ?? NSMakeRange(0, text.characters.count)
            var searchRange = range
            var matchRange = NSRange()
            if text.characters.count >= range.location + range.length {
                while matchRange.location != NSNotFound  {
                    matchRange = NSString(string: text).range(of: matchString, options: textLink.options, range: searchRange)
                    
                    if matchRange.location != NSNotFound && (matchRange.location + matchRange.length) <= (range.location + range.length) {
                        linkResults.append(LinkResult(detectionType: linkType, range: matchRange, text: matchString, textLink: textLink))
                        
                        // Remaining searchRange
                        let location = matchRange.location + matchRange.length
                        let length = text.characters.count - location
                        searchRange = NSMakeRange(location, length)
                    } else {
                        break
                    }
                }
            }
        }
        
        return linkResults
    }
    
    // TEST: testLinkResultsForUserHandlesWithoutEmojis()
    // TEST: testLinkResultsForUserHandlesWithEmojis()
    internal func linkResultsForUserHandles(inString string: String) -> [LinkResult] {
        return linkResults(for: .UserHandle, regexPattern: userHandleRegex, string: string)
    }

    // TEST: testLinkResultsForHashtagsWithoutEmojis()
    // TEST: testLinkResultsForHashtagsWithEmojis()
    internal func linkResultsForHashtags(inString string: String) -> [LinkResult] {
        return linkResults(for: .Hashtag, regexPattern: hashtagRegex, string: string)
    }

    fileprivate func linkResults(for linkType: LinkDetectionType, regexPattern: String, string: String) -> [LinkResult] {
        var linkResults = [LinkResult]()

        // Setup a regular expression for user handles and hashtags
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
        } catch _ as NSError {
            regex = nil
        }

        // Run the expression and get matches
        let length: Int = text.characters.count
        if let matches = regex?.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, length)) {

            // Add all our ranges to the result
            for match in matches {
                let matchRange = match.range
                let matchString = NSString(string: text).substring(with: matchRange)
                
                if matchRange.length > 1 {
                    linkResults.append(LinkResult(detectionType: linkType, range: matchRange, text: matchString, textLink: nil))
                }
            }
        }

        return linkResults
    }

    fileprivate func linkResultsForURLs(inAttributedString attributedString: NSAttributedString) -> [LinkResult] {
        var linkResults = [LinkResult]()

        // Use a data detector to find urls in the text
        let plainText = attributedString.string

        let dataDetector: NSDataDetector?
        do {
            dataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        } catch _ as NSError {
            dataDetector = nil
        }

        if let dataDetector = dataDetector {
            let matches = dataDetector.matches(in: plainText, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, plainText.characters.count))
            
            // Add a range entry for every url we found
            for match in matches {
                let matchRange = match.range
                
                // If there's a link embedded in the attributes, use that instead of the raw text
                var realURL = attributedString.attribute(NSLinkAttributeName, at: matchRange.location, effectiveRange: nil)
                if realURL == nil {
                    if let range = plainText.rangeFromNSRange(matchRange) {
                        realURL = plainText.substring(with: range)
                    }
                }
                
                if match.resultType == .link {
                    if let matchString = realURL as? String {
                        linkResults.append(LinkResult(detectionType: LinkDetectionType.URL, range: matchRange, text: matchString, textLink: nil))
                    }
                }
            }
        }

        return linkResults
    }
    
    fileprivate func addLinkAttributesTo(_ attributedString: NSAttributedString, with linkResults: [LinkResult], highlighted: Bool = false) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        for linkResult in linkResults {
            var attributes: [String: AnyObject]?
            
            if linkResult.detectionType == .TextLink {
                let textColors = textLinkTextColor(linkResult)
                let color = (highlighted) ? textColors.highlightedTextColor ?? highlightedTextColor(textColors.textColor) : textColors.textColor
                
                attributes = attributesWithTextColor(color, underlineStyle: textLinkUnderlineStyle(linkResult))
            }
            
            if linkResult.detectionType == .UserHandle {
                let textColors = userHandleTextColor(linkResult)
                let color = (highlighted) ? textColors.highlightedTextColor ?? highlightedTextColor(textColors.textColor) : textColors.textColor
                
                attributes = attributesWithTextColor(color, underlineStyle: userHandleUnderlineStyle(linkResult))
            }
            
            if linkResult.detectionType == .Hashtag {
                let textColors = hashtagTextColor(linkResult)
                let color = (highlighted) ? textColors.highlightedTextColor ?? highlightedTextColor(textColors.textColor) : textColors.textColor
                
                attributes = attributesWithTextColor(color, underlineStyle: hashtagUnderlineStyle(linkResult))
            }
            
            if linkResult.detectionType == .URL {
                let textColors = textLinkTextColor(linkResult)
                let color = (highlighted) ? textColors.highlightedTextColor ?? highlightedTextColor(textColors.textColor) : textColors.textColor
                
                attributes = attributesWithTextColor(color, underlineStyle: linkUnderlineStyle(linkResult))
            }
            
            if let attributes = attributes {
                mutableAttributedString.setAttributes(attributes, range: linkResult.range)
            }
        }
        
        return mutableAttributedString
    }
    
    fileprivate func addLinkAttributesToLinkResult(withTouches touches: Set<UITouch>!, highlighted: Bool) {
        if let linkResult = linkResult(with: touches), let attributedText = attributedText {
            self.attributedText = addLinkAttributesTo(attributedText, with: [linkResult], highlighted: highlighted)
        }
    }
    
    fileprivate func linkResult(with touches: Set<UITouch>!) -> LinkResult? {
        if let touchLocation = touches.first?.location(in: self), let touchedLink = linkResult(at: touchLocation) {
            return touchedLink
        }
        return nil
    }
    
    fileprivate func linkResult(at location: CGPoint) -> LinkResult? {
        var fractionOfDistance: CGFloat = 0.0
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &fractionOfDistance)
        
        if characterIndex <= textStorage?.length {
            if let linkResults = contextLabelData?.linkResults {
                for linkResult in linkResults {
                    let rangeLocation = linkResult.range.location
                    let rangeLength = linkResult.range.length
                    
                    if rangeLocation <= characterIndex &&
                        (rangeLocation + rangeLength - 1) >= characterIndex {
                            
                            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSMakeRange(rangeLocation, rangeLength), actualCharacterRange: nil)
                            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                            
                            if boundingRect.contains(location) {
                                return linkResult
                            }
                    }
                }
            }
        }
        
        return nil
    }
    
    fileprivate func highlightedTextColor(_ textColor: UIColor) -> UIColor {
        return textColor.withAlphaComponent(0.5)
    }
}

extension String {
    
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        if let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex) {
            if let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex) {
                if let from = String.Index(from16, within: self), let to = String.Index(to16, within: self) {
                    return from ..< to
                }
            }
        }
        return nil
    }
    
    func NSRangeFromRange(_ range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)
        
        return NSMakeRange(utf16view.distance(from: from, to: from), utf16view.distance(from: from, to: to))
    }
}








/**
 A `RealmCollectionChange` value encapsulates information about changes to collections
 that are reported by Realm notifications.
 
 The change information is available in two formats: a simple array of row
 indices in the collection for each type of change, and an array of index paths
 in a requested section suitable for passing directly to `UITableView`'s batch
 update methods.
 
 The arrays of indices in the `.Update` case follow `UITableView`'s batching
 conventions, and can be passed as-is to a table view's batch update functions after being converted to index paths.
 For example, for a simple one-section table view, you can do the following:
 
 ```swift
 self.notificationToken = results.addNotificationBlock { changes in
 switch changes {
 case .initial:
 // Results are now populated and can be accessed without blocking the UI
 self.tableView.reloadData()
 break
 case .update(_, let deletions, let insertions, let modifications):
 // Query results have changed, so apply them to the TableView
 self.tableView.beginUpdates()
 self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) },
 withRowAnimation: .Automatic)
 self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) },
 withRowAnimation: .Automatic)
 self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) },
 withRowAnimation: .Automatic)
 self.tableView.endUpdates()
 break
 case .error(let err):
 // An error occurred while opening the Realm file on the background worker thread
 fatalError("\(err)")
 break
 }
 }
 ```
 */
//public enum RealmCollectionChange<T> {
//    /**
//     `.initial` indicates that the initial run of the query has completed (if applicable), and the collection can now be
//     used without performing any blocking work.
//     */
//    case initial(T)
//
//    /**
//     `.update` indicates that a write transaction has been committed which either changed which objects
//     are in the collection, and/or modified one or more of the objects in the collection.
//
//     All three of the change arrays are always sorted in ascending order.
//
//     - parameter deletions:     The indices in the previous version of the collection which were removed from this one.
//     - parameter insertions:    The indices in the new collection which were added in this version.
//     - parameter modifications: The indices of the objects in the new collection which were modified in this version.
//     */
//    case update(T, deletions: [Int], insertions: [Int], modifications: [Int])
//
//    /**
//     If an error occurs, notification blocks are called one time with a `.error` result and an `NSError` containing
//     details about the error. This can only currently happen if the Realm is opened on a background worker thread to
//     calculate the change set.
//     */
//    case error(Swift.Error)
//
//    static func fromObjc(value: T, change: RLMCollectionChange?, error: Swift.Error?) -> RealmCollectionChange {
//        if let error = error {
//            return .error(error)
//        }
//        if let change = change {
//            return .update(value,
//                           deletions: change.deletions as [Int],
//                           insertions: change.insertions as [Int],
//                           modifications: change.modifications as [Int])
//        }
//        return .initial(value)
//    }
//}








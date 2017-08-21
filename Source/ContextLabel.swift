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
    public let linkResult: LinkResult?
    public let touches: Set<UITouch>
    public let event: UIEvent?
    public let state: UIGestureRecognizerState
}


public struct TextLink {
    public let text: String
    public let range: NSRange?
    public let options: NSString.CompareOptions
    public let object: Any?
    public let action: ()->()
        
    public init(text: String, range: NSRange? = nil, options: NSString.CompareOptions = [], object: Any? = nil, action: @escaping ()->()) {
        self.text = text
        self.range = range
        self.options = options
        self.object = object
        self.action = action
    }
}

open class ContextLabel: UILabel, NSLayoutManagerDelegate, UIGestureRecognizerDelegate {
    
    public enum LinkDetectionType {
        case none
        case userHandle
        case hashtag
        case url
        case textLink
    }
  
    let hashtagRegex = "(?<=\\s|^)#(\\w*[A-Za-z&_-]+\\w*)"
    let userHandleRegex = "(?<=\\s|^)@(\\w*[A-Za-z&_-]+\\w*)"
    
    // MARK: - Closures
    
    public var foregroundColor: (LinkResult) -> UIColor = { (linkResult) in
        switch linkResult.detectionType {
        case .userHandle:
            return UIColor(red: 71.0/255.0, green: 90.0/255.0, blue: 109.0/255.0, alpha: 1.0)
        case .hashtag:
            return UIColor(red: 151.0/255.0, green: 154.0/255.0, blue: 158.0/255.0, alpha: 1.0)
        case .url:
            return UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        case .textLink:
            return UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        default:
            return .black
        }
    }
    
    public var foregroundHighlightedColor: (LinkResult) -> UIColor? = { (linkResult) in
        return nil
    }
    
    public var underlineStyle: (LinkResult) -> (NSUnderlineStyle) = { _ in
        return .styleNone
    }

    public var didTouch: (TouchResult) -> Void = { _ in }

    public var didCopy: (String!) -> Void = { _ in }

    // MARK: - Properties
    
    public var touchState: UIGestureRecognizerState = .possible
    
    // LineSpacing
    public var lineSpacing: CGFloat?
    public var lineHeightMultiple: CGFloat?

    public var canCopy: Bool = false {
        didSet {
            longPressGestureRecognizer.isEnabled = canCopy
        }
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

    // Automatic detection of links, hashtags and usernames. When this is enabled links
    // are coloured using the textColor property above
    public var automaticLinkDetectionEnabled: Bool = true {
        didSet {
            setContextLabelDataWithText(nil)
        }
    }
    
    // linkDetectionTypes
    public var linkDetectionTypes: [LinkDetectionType] = [.userHandle, .hashtag, .url, .textLink] {
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
    
    public lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let _recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        _recognizer.delegate = self
        return _recognizer
    }()
    
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
    } else {
      self.contextLabelData = nil
    }
    
    open override var text: String! {
        didSet {
            setContextLabelDataWithText(text)
        }
    }

    open override var textColor: UIColor! {
        didSet {
            _textColor = textColor
        }
    }

    fileprivate var _textColor = UIColor.black
    
    // MARK: - Initializations
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    public convenience init(frame: CGRect, didTouch: @escaping (TouchResult) -> Void) {
        self.init(frame: frame)
        
        self.didTouch = didTouch
        setup()
    }
    
    // MARK: - Override Properties
    
    open override var canBecomeFirstResponder: Bool {
        return canCopy
    }
    
    
    // MARK: - Override Methods

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:)) && canCopy
    }
    
    open override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
        didCopy(text)
    }
    
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
        touchState = .began
        
        if let linkResult = linkResult(with: touches) {
            selectedLinkResult = linkResult
            didTouch(TouchResult(linkResult: linkResult, touches: touches, event: event, state: .began))
        } else {
            selectedLinkResult = nil
            didTouch(TouchResult(linkResult: nil, touches: touches, event: event, state: .began))
        }
        
        addLinkAttributesToLinkResult(withTouches: touches, highlighted: true)

        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchState = .changed
        
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
            didTouch(TouchResult(linkResult: nil, touches: touches, event: event, state: .changed))
        }
        
        super.touchesMoved(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchState = .ended
        
        addLinkAttributesToLinkResult(withTouches: touches, highlighted: false)

        if let selectedLinkResult = selectedLinkResult {
            didTouch(TouchResult(linkResult: selectedLinkResult, touches: touches, event: event, state: .ended))
            selectedLinkResult.textLink?.action()
        } else {
            didTouch(TouchResult(linkResult: nil, touches: touches, event: event, state: .ended))
        }
        
        selectedLinkResult = nil
        
        super.touchesEnded(touches, with: event)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchState = .cancelled
        
        addLinkAttributesToLinkResult(withTouches: touches, highlighted: false)
        
        didTouch(TouchResult(linkResult: nil, touches: touches, event: event, state: .cancelled))
        
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
    
    open func attributesFromProperties() -> [String : Any] {
        
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
        var color = _textColor
        if self.isEnabled == false {
            color = .lightGray
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
        var attributes: [String : Any] = [
                NSShadowAttributeName: shadow,
                NSParagraphStyleAttributeName: mutableParagraphStyle,
                NSForegroundColorAttributeName: color
        ]

        if let font = self.font {
            attributes[NSFontAttributeName] = font
        }

        return attributes
    }
    
    fileprivate func attributesWithTextColor(_ textColor: UIColor) -> [String: Any] {
        var attributes = attributesFromProperties()
        attributes[NSForegroundColorAttributeName] = textColor
        
        return attributes
    }
    
    fileprivate func attributesWithTextColor(_ textColor: UIColor, underlineStyle: NSUnderlineStyle) -> [String: Any] {
        var attributes = attributesWithTextColor(textColor)
        attributes[NSUnderlineStyleAttributeName] = underlineStyle.rawValue
        
        return attributes
    }
    
    fileprivate func setup() {
        lineBreakMode = .byTruncatingTail
        
        // Attach the layou manager to the container and storage
        textContainer.layoutManager = self.layoutManager

        // Make sure user interaction is enabled so we can accept touches
        isUserInteractionEnabled = true

        // Establish the text store with our current text
        setContextLabelDataWithText(nil)
        addGestureRecognizer(longPressGestureRecognizer)
    }
    
    // Returns array of link results for all special words, user handles, hashtags and urls
    fileprivate func linkResults(in attributedString: NSAttributedString) -> [LinkResult] {
        var linkResults = [LinkResult]()

        if let textLinks = textLinks {
            linkResults += linkResultsForTextLinks(textLinks)
        }
        
        if linkDetectionTypes.contains(.userHandle) {
            linkResults += linkResultsForUserHandles(inString: attributedString.string)
        }

        if linkDetectionTypes.contains(.hashtag) {
            linkResults += linkResultsForHashtags(inString: attributedString.string)
        }

        if linkDetectionTypes.contains(.url) {
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
            let linkType = LinkDetectionType.textLink
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
        return linkResults(for: .userHandle, regexPattern: userHandleRegex, string: string)
    }

    // TEST: testLinkResultsForHashtagsWithoutEmojis()
    // TEST: testLinkResultsForHashtagsWithEmojis()
    internal func linkResultsForHashtags(inString string: String) -> [LinkResult] {
        return linkResults(for: .hashtag, regexPattern: hashtagRegex, string: string)
    }

    fileprivate func linkResults(for linkType: LinkDetectionType, regexPattern: String, string: String) -> [LinkResult] {
        var linkResults = [LinkResult]()
        
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
            return linkResults
        }

        // Run the expression and get matches
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, nsString.length))

        // Add all our ranges to the result
        for match in matches {
            let matchRange = match.range
            let matchString = NSString(string: text).substring(with: matchRange)
            
            if matchRange.length > 1 {
                linkResults.append(LinkResult(detectionType: linkType, range: matchRange, text: matchString, textLink: nil))
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
                        linkResults.append(LinkResult(detectionType: .url, range: matchRange, text: matchString, textLink: nil))
                    }
                }
            }
        }

        return linkResults
    }

    fileprivate func addLinkAttributesTo(_ attributedString: NSAttributedString, with linkResults: [LinkResult], highlighted: Bool = false) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        for linkResult in linkResults {
            let textColor = foregroundColor(linkResult)
            let highlightedTextColor = foregroundHighlightedColor(linkResult)
            let color = (highlighted) ? highlightedTextColor ?? self.highlightedTextColor(textColor) : textColor
            let attributes = attributesWithTextColor(color, underlineStyle: self.underlineStyle(linkResult))

            mutableAttributedString.setAttributes(attributes, range: linkResult.range)
        }
        return mutableAttributedString
    }
    
    fileprivate func addLinkAttributesToLinkResult(withTouches touches: Set<UITouch>!, highlighted: Bool) {
        if let linkResult = linkResult(with: touches), let attributedText = attributedText {
            self.attributedText = addLinkAttributesTo(attributedText, with: [linkResult], highlighted: highlighted)
        }
    }
    
    fileprivate func linkResult(with touches: Set<UITouch>!) -> LinkResult? {
        guard let touchLocation = touches.first?.location(in: self) else { return nil }
        return linkResult(at: touchLocation)
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
                            var boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                            boundingRect.origin.y += (bounds.height - intrinsicContentSize.height) / 2
                        
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
    
    // MARK: Actions
    
    func longPressGestureRecognized(_ sender: UILongPressGestureRecognizer) {
        if let superview = superview, canCopy, sender.state == .began {
            becomeFirstResponder()
            let menu = UIMenuController.shared
            menu.setTargetRect(frame, in: superview)
            menu.setMenuVisible(true, animated: true)
        }
    }
}

extension ContextLabel {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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

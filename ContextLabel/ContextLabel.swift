//
//  ContextLabel.swift
//  ContextLabel
//
//  Created by Michael Loistl on 25/08/2014.
//  Copyright (c) 2014 Michael Loistl. All rights reserved.
//

import Foundation
import UIKit

public protocol ContextLabelDelegate {
    func contextLabel(contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult)
    func contextLabel(contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult)
    func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult)

    func contextLabel(contextLabel: ContextLabel, textLinkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
    func contextLabel(contextLabel: ContextLabel, userHandleTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
    func contextLabel(contextLabel: ContextLabel, hashtagTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
    func contextLabel(contextLabel: ContextLabel, linkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
}

public extension ContextLabelDelegate {
    
    func contextLabel(contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult) {
        
    }
    
    func contextLabel(contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult) {
        
    }
    
    func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult) {
        
    }

    func contextLabel(contextLabel: ContextLabel, textLinkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
        return nil
    }
    
    func contextLabel(contextLabel: ContextLabel, userHandleTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
        return nil
    }
    
    func contextLabel(contextLabel: ContextLabel, hashtagTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
        return nil
    }
    
    func contextLabel(contextLabel: ContextLabel, linkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor? {
        return nil
    }
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

public struct LinkRangeResult {
    public let linkDetectionType: ContextLabel.LinkDetectionType
    public let linkRange: NSRange
    public let linkString: String
    public let textLink: TextLink?
}

public struct TextLink {
    public let text: String
    public let range: NSRange?
    public let options: NSStringCompareOptions
    public let action: ()->()
        
    public init(text: String, range: NSRange? = nil, options: NSStringCompareOptions = [], action: ()->()) {
        self.text = text
        self.range = range
        self.options = options
        self.action = action
    }
}

public class ContextLabel: UILabel, NSLayoutManagerDelegate {
    
    public struct LinkDetectionType : OptionSetType {
        public typealias RawValue = UInt
        private var value: UInt = 0
        init(_ value: UInt) { self.value = value }
        public init(rawValue value: UInt) { self.value = value }
        init(nilLiteral: ()) { self.value = 0 }
        static var allZeros: LinkDetectionType { return self.init(0) }
        static func fromMask(raw: UInt) -> LinkDetectionType { return self.init(raw) }
        public var rawValue: UInt { return self.value }
        
        static var None: LinkDetectionType { return self.init(0) }
        static var UserHandle: LinkDetectionType { return LinkDetectionType(1 << 0) }
        static var Hashtag: LinkDetectionType { return LinkDetectionType(1 << 1) }
        static var URL: LinkDetectionType { return LinkDetectionType(1 << 2) }
        static var TextLink: LinkDetectionType { return LinkDetectionType(1 << 3) }
    }
  
    let hashtagRegex = "(?<=\\s|^)#(\\w*[A-Za-z&_-]+\\w*)"
    let userHandleRegex = "(?<=\\s|^)@(\\w*[A-Za-z&_-]+\\w*)"
    
//    let emojiRegex = "[\u{00002712}\u{00002714}\u{00002716}\u{0000271d}\u{00002721}\u{00002728}\u{00002733}\u{00002734}\u{00002744}\u{00002747}\u{0000274c}\u{0000274e}\u{00002753}-\u{00002755}\u{00002757}\u{00002763}\u{00002764}\u{00002795}-\u{00002797}\u{000027a1}\u{000027b0}\u{000027bf}\u{00002934}\u{00002935}\u{00002b05}-\u{00002b07}\u{00002b1b}\u{00002b1c}\u{00002b50}\u{00002b55}\u{00003030}\u{0000303d}\u{0001f004}\u{0001f0cf}\u{0001f170}\u{0001f171}\u{0001f17e}\u{0001f17f}\u{0001f18e}\u{0001f191}-\u{0001f19a}\u{0001f201}\u{0001f202}\u{0001f21a}\u{0001f22f}\u{0001f232}-\u{0001f23a}\u{0001f250}\u{0001f251}\u{0001f300}-\u{0001f321}\u{0001f324}-\u{0001f393}\u{0001f396}\u{0001f397}\u{0001f399}-\u{0001f39b}\u{0001f39e}-\u{0001f3f0}\u{0001f3f3}-\u{0001f3f5}\u{0001f3f7}-\u{0001f4fd}\u{0001f4ff}-\u{0001f53d}\u{0001f549}-\u{0001f54e}\u{0001f550}-\u{0001f567}\u{0001f56f}\u{0001f570}\u{0001f573}-\u{0001f579}\u{0001f587}\u{0001f58a}-\u{0001f58d}\u{0001f590}\u{0001f595}\u{0001f596}\u{0001f5a5}\u{0001f5a8}\u{0001f5b1}\u{0001f5b2}\u{0001f5bc}\u{0001f5c2}-\u{0001f5c4}\u{0001f5d1}-\u{0001f5d3}\u{0001f5dc}-\u{0001f5de}\u{0001f5e1}\u{0001f5e3}\u{0001f5ef}\u{0001f5f3}\u{0001f5fa}-\u{0001f64f}\u{0001f680}-\u{0001f6c5}\u{0001f6cb}-\u{0001f6d0}\u{0001f6e0}-\U0001f6e5\U0001f6e9\U0001f6eb\U0001f6ec\U0001f6f0\U0001f6f3\U0001f910-\U0001f918\U0001f980-\U0001f984\U0001f9c0\U00003297\U00003299\U000000a9\U000000ae\U0000203c\U00002049\U00002122\U00002139\U00002194-\U00002199\U000021a9\U000021aa\U0000231a\U0000231b\U00002328\U00002388\U000023cf\U000023e9-\U000023f3\U000023f8-\U000023fa\U000024c2\U000025aa\U000025ab\U000025b6\U000025c0\U000025fb-\U000025fe\U00002600-\U00002604\U0000260e\U00002611\U00002614\U00002615\U00002618\U0000261d\U00002620\U00002622\U00002623\U00002626\U0000262a\U0000262e\U0000262f\U00002638-\U0000263a\U00002648-\U00002653\U00002660\U00002663\U00002665\U00002666\U00002668\U0000267b\U0000267f\U00002692-\U00002694\U00002696\U00002697\U00002699\U0000269b\U0000269c\U000026a0\U000026a1\U000026aa\U000026ab\U000026b0\U000026b1\U000026bd\U000026be\U000026c4\U000026c5\U000026c8\U000026ce\U000026cf\U000026d1\U000026d3\U000026d4\U000026e9\U000026ea\U000026f0-\U000026f5\U000026f7-\U000026fa\U000026fd\U00002702\U00002705\U00002708-\U0000270d\U0000270f]|[#]\U000020e3|[*]\U000020e3|[0]\U000020e3|[1]\U000020e3|[2]\U000020e3|[3]\U000020e3|[4]\U000020e3|[5]\U000020e3|[6]\U000020e3|[7]\U000020e3|[8]\U000020e3|[9]\U000020e3|\U0001f1e6[\U0001f1e8-\U0001f1ec\U0001f1ee\U0001f1f1\U0001f1f2\U0001f1f4\U0001f1f6-\U0001f1fa\U0001f1fc\U0001f1fd\U0001f1ff]|\U0001f1e7[\U0001f1e6\U0001f1e7\U0001f1e9-\U0001f1ef\U0001f1f1-\U0001f1f4\U0001f1f6-\U0001f1f9\U0001f1fb\U0001f1fc\U0001f1fe\U0001f1ff]|\U0001f1e8[\U0001f1e6\U0001f1e8\U0001f1e9\U0001f1eb-\U0001f1ee\U0001f1f0-\U0001f1f5\U0001f1f7\U0001f1fa-\U0001f1ff]|\U0001f1e9[\U0001f1ea\U0001f1ec\U0001f1ef\U0001f1f0\U0001f1f2\U0001f1f4\U0001f1ff]|\U0001f1ea[\U0001f1e6\U0001f1e8\U0001f1ea\U0001f1ec\U0001f1ed\U0001f1f7-\U0001f1fa]|\U0001f1eb[\U0001f1ee-\U0001f1f0\U0001f1f2\U0001f1f4\U0001f1f7]|\U0001f1ec[\U0001f1e6\U0001f1e7\U0001f1e9-\U0001f1ee\U0001f1f1-\U0001f1f3\U0001f1f5-\U0001f1fa\U0001f1fc\U0001f1fe]|\U0001f1ed[\U0001f1f0\U0001f1f2\U0001f1f3\U0001f1f7\U0001f1f9\U0001f1fa]|\U0001f1ee[\U0001f1e8-\U0001f1ea\U0001f1f1-\U0001f1f4\U0001f1f6-\U0001f1f9]|\U0001f1ef[\U0001f1ea\U0001f1f2\U0001f1f4\U0001f1f5]|\U0001f1f0[\U0001f1ea\U0001f1ec-\U0001f1ee\U0001f1f2\U0001f1f3\U0001f1f5\U0001f1f7\U0001f1fc\U0001f1fe\U0001f1ff]|\U0001f1f1[\U0001f1e6-\U0001f1e8\U0001f1ee\U0001f1f0\U0001f1f7-\U0001f1fb\U0001f1fe]|\U0001f1f2[\U0001f1e6\U0001f1e8-\U0001f1ed\U0001f1f0-\U0001f1ff]|\U0001f1f3[\U0001f1e6\U0001f1e8\U0001f1ea-\U0001f1ec\U0001f1ee\U0001f1f1\U0001f1f4\U0001f1f5\U0001f1f7\U0001f1fa\U0001f1ff]|\U0001f1f4\U0001f1f2|\U0001f1f5[\U0001f1e6\U0001f1ea-\U0001f1ed\U0001f1f0-\U0001f1f3\U0001f1f7-\U0001f1f9\U0001f1fc\U0001f1fe]|\U0001f1f6\U0001f1e6|\U0001f1f7[\U0001f1ea\U0001f1f4\U0001f1f8\U0001f1fa\U0001f1fc]|\U0001f1f8[\U0001f1e6-\U0001f1ea\U0001f1ec-\U0001f1f4\U0001f1f7-\U0001f1f9\U0001f1fb\U0001f1fd-\U0001f1ff]|\U0001f1f9[\U0001f1e6\U0001f1e8\U0001f1e9\U0001f1eb-\U0001f1ed\U0001f1ef-\U0001f1f4\U0001f1f7\U0001f1f9\U0001f1fb\U0001f1fc\U0001f1ff]|\U0001f1fa[\U0001f1e6\U0001f1ec\U0001f1f2\U0001f1f8\U0001f1fe\U0001f1ff]|\U0001f1fb[\U0001f1e6\U0001f1e8\U0001f1ea\U0001f1ec\U0001f1ee\U0001f1f3\U0001f1fa]|\U0001f1fc[\U0001f1eb\U0001f1f8]|\U0001f1fd\U0001f1f0|\U0001f1fe[\U0001f1ea\U0001f1f9]|\U0001f1ff[\U0001f1e6\U0001f1f2\U0001f1fc]"

    // Delegate
    public var delegate: ContextLabelDelegate?
    
    // MARK: - Config Properties
    
    // LineSpacing
    public var lineSpacing: CGFloat?
    public var lineHeightMultiple: CGFloat?
    
    // TextColors
    public var textLinkTextColor = UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    public var userHandleTextColor = UIColor(red: 71.0/255.0, green: 90.0/255.0, blue: 109.0/255.0, alpha: 1.0)
    public var hashtagTextColor = UIColor(red: 151.0/255.0, green: 154.0/255.0, blue: 158.0/255.0, alpha: 1.0)
    public var linkTextColor = UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    
    // TextHighlightColors
    public var textLinkHighlightedTextColor: UIColor?
    public var userHandleHighlightedTextColor: UIColor?
    public var hashtagHighlightedTextColor: UIColor?
    public var linkHighlightedTextColor: UIColor?
    
    // UnderlineStyle
    public var textLinkUnderlineStyle: NSUnderlineStyle = .StyleNone
    public var userHandleUnderlineStyle: NSUnderlineStyle = .StyleNone
    public var hashtagUnderlineStyle: NSUnderlineStyle = .StyleNone
    public var linkUnderlineStyle: NSUnderlineStyle = .StyleNone
    
    public var preferedHeight: CGFloat? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public var preferedWidth: CGFloat? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Private Properties
    
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

    // MARK: - Properties
    
    // Automatic detection of links, hashtags and usernames. When this is enabled links
    // are coloured using the textColor property above
    var automaticLinkDetectionEnabled: Bool = true {
        didSet {
            setContextLabelDataWithText(nil)
        }
    }
    
    // linkDetectionTypes
    var linkDetectionTypes: LinkDetectionType = [.UserHandle, .Hashtag, .URL, .TextLink] {
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
    
    
    // MARK: - Properties override

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
    
    
    // MARK: - Initializations
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupTextSystem()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupTextSystem()
    }
    
    public convenience init(with userHandleTextColor: UIColor, hashtagTextColor: UIColor, linkTextColor: UIColor) {
        self.init(frame:CGRectZero)
        
        self.userHandleTextColor = userHandleTextColor
        self.hashtagTextColor = hashtagTextColor
        self.linkTextColor = linkTextColor
    }
    
    
    // MARK: - Override Methods
    
    override public func intrinsicContentSize() -> CGSize {
        var width = super.intrinsicContentSize().width
        var height = super.intrinsicContentSize().height
        
        if let preferedWidth = preferedWidth {
            width = preferedWidth
        }
        
        if let preferedHeight = preferedHeight {
            height = preferedHeight
        }
        
        return CGSize(width: width, height: height)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        textContainer.size = CGSizeMake(CGRectGetWidth(self.bounds), CGFloat.max)
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
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
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {

        if let linkRangeResult = getLinkRangeResultWithTouches(touches) {
            
            if linkRangeResult.linkRange.location != selectedLinkRangeResult?.linkRange.location  {
                if let selectedLinkRangeResult = selectedLinkRangeResult, attributedText = attributedText {
                    self.attributedText = addLinkAttributesToAttributedString(attributedText, withLinkRangeResults: [selectedLinkRangeResult], highlighted: false)
                }
            }
            
            addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: true)
            
            selectedLinkRangeResult = linkRangeResult
            
            // Call delegate
            if let selectedLinkRangeResult = selectedLinkRangeResult {
                delegate?.contextLabel(self, movedTouchTo: selectedLinkRangeResult.linkString, with: selectedLinkRangeResult)
            }
            
        } else {
            if let selectedLinkRangeResult = selectedLinkRangeResult, attributedText = attributedText {
                self.attributedText = addLinkAttributesToAttributedString(attributedText, withLinkRangeResults: [selectedLinkRangeResult], highlighted: false)
            }
            
            selectedLinkRangeResult = nil
        }
        
        super.touchesMoved(touches, withEvent: event)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: false)
        
        // Call delegate
        if let selectedLinkRangeResult = selectedLinkRangeResult {
            delegate?.contextLabel(self, endedTouchOf: selectedLinkRangeResult.linkString, with: selectedLinkRangeResult)
            selectedLinkRangeResult.textLink?.action()
        }
        
        selectedLinkRangeResult = nil
        
        super.touchesEnded(touches, withEvent: event)
    }

    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        addLinkAttributesToLinkRangeResultWithTouches(touches, highlighted: false)
        super.touchesCancelled(touches, withEvent: event)
    }
    
    // MARK: - Methods
    
    func addAttributes(attributes: Dictionary<String, AnyObject>, range: NSRange) {
        if let contextLabelData = contextLabelData {
            let mutableAttributedString = NSMutableAttributedString(attributedString: contextLabelData.attributedString)
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
            let mutableAttributedString = NSMutableAttributedString(string: text, attributes: attributesFromProperties())
            let linkRangeResults = getRangesForLinksInAttributedString(mutableAttributedString)
            
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
    
    public func attributesFromProperties() -> [String : AnyObject] {
        
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
        let attributes = [NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: color,
            NSShadowAttributeName: shadow,
            NSParagraphStyleAttributeName: mutableParagraphStyle]
        
        return attributes
    }
    
    private func attributesWithTextColor(textColor: UIColor) -> [String: AnyObject] {
        var attributes = attributesFromProperties()
        attributes[NSForegroundColorAttributeName] = textColor
        
        return attributes
    }
    
    private func attributesWithTextColor(textColor: UIColor, underlineStyle: NSUnderlineStyle) -> [String: AnyObject] {
        var attributes = attributesWithTextColor(textColor)
        attributes[NSUnderlineStyleAttributeName] = underlineStyle.rawValue
        
        return attributes
    }
    
    private func setupTextSystem() {
        lineBreakMode = .ByTruncatingTail
        
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
        
        if linkDetectionTypes.intersect(.UserHandle) != [] {
            rangesForLinks += getRangesForUserHandlesInText(attributedString.string)
        }

        if linkDetectionTypes.intersect(.Hashtag) != [] {
            rangesForLinks += getRangesForHashtagsInText(attributedString.string)
        }

        if linkDetectionTypes.intersect(.URL) != [] {
            rangesForLinks += getRangesForURLsInAttributedString(attributedString)
        }

        return rangesForLinks
    }

    // TEST: testGetRangesForTextLinksWithoutEmojis()
    // TEST: testGetRangesForTextLinksWithEmojis()
    // TEST: testGetRangesForTextLinksWithMultipleOccuranciesWithoutRange()
    // TEST: testGetRangesForTextLinksWithMultipleOccuranciesWithRange()
    func getRangesForTextLinks(textLinks: [TextLink]) -> [LinkRangeResult] {
        var rangesForLinkType = [LinkRangeResult]()
        
        for textLink in textLinks {
            let linkType = LinkDetectionType.TextLink
            let matchString = textLink.text
            
            let range = textLink.range ?? NSMakeRange(0, text.characters.count)
            var searchRange = range
            var matchRange = NSRange()
            if text.characters.count >= range.location + range.length {
                while matchRange.location != NSNotFound  {
                    matchRange = NSString(string: text).rangeOfString(matchString, options: textLink.options, range: searchRange)
                    
                    if matchRange.location != NSNotFound && (matchRange.location + matchRange.length) <= (range.location + range.length) {
                        rangesForLinkType.append(LinkRangeResult(linkDetectionType: linkType, linkRange: matchRange, linkString: matchString, textLink: textLink))
                        
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
        
        return rangesForLinkType
    }
    
    // TEST: testGetRangesForUserHandlesInTextWithoutEmojis()
    // TEST: testGetRangesForUserHandlesInTextWithEmojis()
    func getRangesForUserHandlesInText(text: String) -> [LinkRangeResult] {
        let rangesForUserHandles = getRangesForLinkType(LinkDetectionType.UserHandle, regexPattern: userHandleRegex, text: text)
        return rangesForUserHandles
    }

    // TEST: testGetRangesForHashtagsInTextWithoutEmojis()
    // TEST: testGetRangesForHashtagsInTextWithEmojis()
    func getRangesForHashtagsInText(text: String) -> [LinkRangeResult] {
        let rangesForHashtags = getRangesForLinkType(LinkDetectionType.Hashtag, regexPattern: hashtagRegex, text: text)
        return rangesForHashtags
    }

    private func getRangesForLinkType(linkType: LinkDetectionType, regexPattern: String, text: String) -> [LinkRangeResult] {
        var rangesForLinkType = [LinkRangeResult]()

        // Setup a regular expression for user handles and hashtags
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: regexPattern, options: .CaseInsensitive)
        } catch _ as NSError {
            regex = nil
        }

        // Run the expression and get matches
        let length: Int = text.characters.count
        if let matches = regex?.matchesInString(text, options: .ReportCompletion, range: NSMakeRange(0, length)) {

            // Add all our ranges to the result
            for match in matches {
                let matchRange = match.range
                let matchString = NSString(string: text).substringWithRange(matchRange)
                
                if matchRange.length > 1 {
                    rangesForLinkType.append(LinkRangeResult(linkDetectionType: linkType, linkRange: matchRange, linkString: matchString, textLink: nil))
                }
            }
        }

        return rangesForLinkType
    }

    private func getRangesForURLsInAttributedString(attributedString: NSAttributedString) -> [LinkRangeResult] {
        var rangesForURLs = [LinkRangeResult]()

        // Use a data detector to find urls in the text
        let plainText = attributedString.string

        let dataDetector: NSDataDetector?
        do {
            dataDetector = try NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        } catch _ as NSError {
            dataDetector = nil
        }

        if let dataDetector = dataDetector {
            let matches = dataDetector.matchesInString(plainText, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, plainText.characters.count))
            
            // Add a range entry for every url we found
            for match in matches {
                let matchRange = match.range
                
                // If there's a link embedded in the attributes, use that instead of the raw text
                var realURL: AnyObject? = attributedString.attribute(NSLinkAttributeName, atIndex: matchRange.location, effectiveRange: nil)
                if realURL == nil {
                    realURL = NSString(string: plainText).substringWithRange(matchRange)
                }
                
                if match.resultType == .Link {
                    if let matchString = realURL as? String {
                        rangesForURLs.append(LinkRangeResult(linkDetectionType: LinkDetectionType.URL, linkRange: matchRange, linkString: matchString, textLink: nil))
                    }
                }
            }
        }

        return rangesForURLs
    }
    
    private func addLinkAttributesToAttributedString(attributedString: NSAttributedString, withLinkRangeResults linkRangeResults: [LinkRangeResult], highlighted: Bool = false) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        for linkRangeResult in linkRangeResults {
            var attributes: [String: AnyObject]?
            
            if linkRangeResult.linkDetectionType == .TextLink {
                let textLinkTextColor = delegate?.contextLabel(self, textLinkTextColorFor: linkRangeResult) ?? self.textLinkTextColor
                let color = highlighted ? privateTextLinkHighlightedTextColor : textLinkTextColor
                attributes = attributesWithTextColor(color, underlineStyle: textLinkUnderlineStyle)
            }
            
            if linkRangeResult.linkDetectionType == .UserHandle {
                let userHandleTextColor = delegate?.contextLabel(self, userHandleTextColorFor: linkRangeResult) ?? self.userHandleTextColor
                let color = highlighted ? privateUserHandleHighlightedTextColor : userHandleTextColor
                attributes = attributesWithTextColor(color, underlineStyle: userHandleUnderlineStyle)
            }
            
            if linkRangeResult.linkDetectionType == .Hashtag {
                let hashtagTextColor = delegate?.contextLabel(self, hashtagTextColorFor: linkRangeResult) ?? self.hashtagTextColor
                let color = highlighted ? privateHashtagHighlightedTextColor : hashtagTextColor
                attributes = attributesWithTextColor(color, underlineStyle: hashtagUnderlineStyle)
            }
            
            if linkRangeResult.linkDetectionType == .URL {
                let linkTextColor = delegate?.contextLabel(self, linkTextColorFor: linkRangeResult) ?? self.linkTextColor
                let color = highlighted ? privateLinkHighlightedTextColor : linkTextColor
                attributes = attributesWithTextColor(color, underlineStyle: linkUnderlineStyle)
            }
            
            if let attributes = attributes {
                mutableAttributedString.setAttributes(attributes, range: linkRangeResult.linkRange)
            }
        }
        
        return mutableAttributedString
    }
    
    private func addLinkAttributesToLinkRangeResultWithTouches(touches: NSSet!, highlighted: Bool) {
        if let linkRangeResult = getLinkRangeResultWithTouches(touches), attributedText = attributedText {
            self.attributedText = addLinkAttributesToAttributedString(attributedText, withLinkRangeResults: [linkRangeResult], highlighted: highlighted)
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
                    let rangeLocation = linkRangeResult.linkRange.location
                    let rangeLength = linkRangeResult.linkRange.length
                    
                    if rangeLocation <= characterIndex &&
                        (rangeLocation + rangeLength - 1) >= characterIndex {
                            
                            let glyphRange = layoutManager.glyphRangeForCharacterRange(NSMakeRange(rangeLocation, rangeLength), actualCharacterRange: nil)
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

extension String {
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
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
        return NSMakeRange(utf16view.startIndex.distanceTo(from), from.distanceTo(to))
    }
}
[![Build Status](https://travis-ci.org/michaelloistl/ContextLabel.svg?branch=master)](https://travis-ci.org/michaelloistl/ContextLabel)

# ContextLabel

A simple to use drop in replacement for UILabel written in Swift that provides automatic detection of links such as URLs, twitter style usernames and hashtags.

## How to use it in your project
ContextLabel doesn't have any special dependencies so just include the files ContextLabel.swift in your project. Then use the `ContextLabel` class in replacement for `UILabel`.

## Text colors
ContextLabel supports different colors for URLs, twitter style usernames and hashtags. By default the link text colors are set to userHandle RGB(71,90,109), hashtag RGB(151, 154, 158) and url/email/text links RGB(45, 113, 178).

To set your own text colors, return the desired UIColor within the closure value of `foregroundColor`:

``` Swift
contextLabel.foregroundColor = { (linkResult) in
		switch linkResult.detectionType {
    case .userHandle:
        return UIColor(red: 71.0/255.0, green: 90.0/255.0, blue: 109.0/255.0, alpha: 1.0)
    case .hashtag:
        return UIColor(red: 151.0/255.0, green: 154.0/255.0, blue: 158.0/255.0, alpha: 1.0)
    case .url, .email:
        return UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    case .textLink:
        return UIColor(red: 45.0/255.0, green: 113.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    default:
        return .black
    }
}
```

If there is no UIColor returned from `foregroundHighlightedColor`, an alpha of 0.5 is applied to the set text color when a link is detected.

To set your own text highlight colors, return the desired UIColor within the closure value of `underlineStyle`:

``` Swift
contextLabel.foregroundHighlightedColor = { (linkResult) in
    return .lightGray
}
```

## Underline style
By default detected links are not underlined.

To set your own underline style, return the desired NSUnderlineStyle within the closure value of `underlineStyle`:

``` Swift
contextLabel.underlineStyle = { (linkResult) in
    return .styleNone
}
```

## Text links
ContextLabel automatically recognizes words starting with # and @ as well as manually defined text links.

A text link is defined at the minimum by a string `”text link”` and an action which is a closure that gets called when the user touches the defined text. From version 0.3.1, all occurencies of a given text are recognized within the label text. To limit the recognition within the label text, an optional range can be set when initializing a TextLink.

``` Swift
TextLink(text: String, range: NSRange? = nil, options: NSString.CompareOptions = [], action: @escaping ()->())
```

## Selection handling
When tapping the label, the closure `didTouch: (TouchResult) -> Void` will be called for each touch state:

``` Swift
didTouch: { [weak self] (touchResult) in
    switch touchResult.state {
    case .began:
        // Do something
    case .ended:
				// Do something
    default:
        break
    }
}
```

The touch behaviour changed from version [1.2.0](https://github.com/michaelloistl/ContextLabel/releases/tag/1.2.0).

The `touchResult` includes everything you need to take action on the selected string.

``` Swift
public struct TouchResult {
    public let linkResult: LinkResult?
    public let touches: Set<UITouch>
    public let event: UIEvent?
    public let state: UIGestureRecognizerState
}
```

``` Swift
public struct LinkResult {
    public let detectionType: ContextLabel.LinkDetectionType
    public let range: NSRange
    public let text: String
    public let textLink: TextLink?
}
```

``` Swift
public enum LinkDetectionType {
    case none
    case userHandle
    case hashtag
    case url
    case email
    case textLink
}
```

### Use of cache
When setting the text, ContextLabel generates an instance of ’ContextLabelData’ which is a NSObject subclass that can be persisted in order to enable reuse for unchanged data.

’ContextLabelData’ holds the actual `attributedString`, the `linkRangeResults` and a userInfo dictionary which can be used to compare against the model data to see if it’s still valid.

``` swift
if let cachedContextLabelData: ContextLabelData = … {
	// Set cached contextLabelData
	contextLabel.contextLabelData = cachedTextContextLabelData
} else {
	// Set label text
	contextLabel.text = text

	// Cache contextLabelData that has been generated from contextLabel
	cacheContextLabelData(contextLabel.contextLabelData)
}          
```

## License & Credits
ContextLabel is available under the MIT license.

ContextLabel was inspired by KILabel (https://github.com/Krelborn/KILabel).

## Contact
- http://michaelloistl.com
- http://twitter.com/michaelloistl
- http://github.com/michaelloistl

[![Build Status](https://travis-ci.org/michaelloistl/ContextLabel.svg?branch=master)](https://travis-ci.org/michaelloistl/ContextLabel)

# ContextLabel

A simple to use drop in replacement for UILabel written in Swift that provides automatic detection of links such as URLs, twitter style usernames and hashtags.

## How to use it in your project
ContextLabel doesn't have any special dependencies so just include the files ContextLabel.swift in your project. Then use the `ContextLabel` class in replacement for `UILabel`.

## Text colors
ContextLabel supports different colors for URLs, twitter style usernames and hashtags. By default the link text colors are set to userHandle RGB(71,90,109), hashtag RGB(151, 154, 158) and url/text links RGB(45, 113, 178). If there is no UIColor set on the highlighted  textColor properties, an alpha of 0.5 is applied to the set text color when a link is detected.

To set your own text colors you can use the convenience initializer `init(with userHandleTextColor: UIColor, hashtagTextColor: UIColor, linkTextColor: UIColor)` or just set a different UIColor to to properties `textLinkTextColor`, `userHandleTextColor`, `hashtagTextColor` and `linkTextColor` after initializing `ContextLabel`.

From version 0.3.0, text colors can be overwritten by implementing the folowing optional delegate methods:
``` Swift
func contextLabel(contextLabel: ContextLabel, textLinkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
func contextLabel(contextLabel: ContextLabel, userHandleTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
func contextLabel(contextLabel: ContextLabel, hashtagTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
func contextLabel(contextLabel: ContextLabel, linkTextColorFor linkRangeResult: LinkRangeResult) -> UIColor?
```

## Underline style
From version 0.3.0 you can also set the underline style through the properties `textLinkUnderlineStyle`, `userHandleUnderlineStyle`, `hashtagUnderlineStyle` and `linkUnderlineStyle`.

## Selection handling
In order to get the selected string, range, detection type and textLink object you need to implement at least one of the following optional delegate methods, depending on when you want to get the selection:
``` Swift
func contextLabel(contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult)
func contextLabel(contextLabel: ContextLabel, movedTouchTo text: String, with linkRangeResult: LinkRangeResult)
func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult)
```

## LinkRangeResult
Each delegate method includes a `LinkRangeResult` struct which includes
- linkDetectionType: LinkDetectionType
- linkRange: NSRange
- linkString: String
- textLink: TextLink?

## Sample code

### Replacement for UILabel
``` swift
let contextLabel = ContextLabel(frame: CGRectMake(0, 0, 320, 100))
contextLabel.text = "ContextLabel is a Swift drop-in replacement for UILabel that supports selectable @UserHandle, #Hashtags and links https://github.com/michaelloistl/ContextLabel"
contextLabel.delegate = self

view.addSubview(contextLabel)
```

### Use in UITableViewCell

Add instance variable to capture state when user touches text in label:

``` Swift
var contextLabelTouched = false
```

In a tableViewCell you need to overwrite `touchesBegan: withEvent:`

``` Swift
override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if contextLabelTouched == false {
        super.touchesBegan(touches, withEvent: event)
    }
}
```

Here you set the instance variable to skip the cell touch to execute:
``` Swift
func contextLabel(contextLabel: ContextLabel, beganTouchOf text: String, with linkRangeResult: LinkRangeResult) {
    contextLabelTouched = true
}
```

Here you get the touched text from the label which you pass to MFMailComposeViewController
``` Swift
func contextLabel(contextLabel: ContextLabel, endedTouchOf text: String, with linkRangeResult: LinkRangeResult) {
    contextLabelTouched = false
    
    // text = ... is the touched text 
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

# ContextLabel

A simple to use drop in replacement for UILabel written in Swift that provides automatic detection of links such as URLs, twitter style usernames and hashtags.

## How to use it in your project
ContextLabel doesn't have any special dependencies so just include the files ContextLabel.swift from ContextLabel/Source in your project. Then use the ContextLabel class in replacement for UILabel.

## Text colors
ContextLabel support different colors for URLs, twitter style usernames and hashtags. By default the link text colors are set to userHandle RGB(71,90,109), hashtag RGB(151, 154, 158) and url RGB(45, 113, 178). If there is no UIColor set on the highlighted  textColor properties, an alpha of 0.5 is applied to the set text color when a link is detected.

To set your own text colors you can use the convenience initializer ```init(with userHandleTextColor: UIColor, hashtagTextColor: UIColor, linkTextColor: UIColor)```

## Delegate
In order to get the selected string as well as Range you need to adopt the ContextLabelDelegate protocol and implement the ```func contextLabel(contextLabel: ContextLabel, didSelectText: String, inRange: NSRange)```

## Sample code
``` swift
let contextLabel = ContextLabel(frame: CGRectMake(0, 0, 320, 100))
contextLabel.text = "ContextLabel is a Swift drop-in replacement for UILabel that supports selectable @UserHandle, #Hashtags and links https://github.com/michaelloistl/ContextLabel"
contextLabel.delegate = self

view.addSubview(contextLabel)```

## Demo
The Repository includes a Xcode project that shows a simple use of the label in a storyboard with examples for implementing tappable links.

## License & Credits
ContextLabel is available under the MIT license.

KILabel was inspired by KILabel (https://github.com/Krelborn/KILabel).

## Contact
- http://twitter.com/michaelloistl
- http://github.com/michaelloistl

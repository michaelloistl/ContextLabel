Pod::Spec.new do |s|
    s.name = 'ContextLabel'
    s.version = '1.3.0'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.summary = 'A simple to use drop in replacement for UILabel'
    s.description = 'A simple to use drop in replacement for UILabel written in Swift that provides automatic detection of links such as URLs, twitter style usernames and hashtags.'
    s.authors = { 'Michael Loistl' => 'michael@aplo.io' }
    s.homepage = "https://github.com/michaelloistl/ContextLabel"
    s.source = { :git => 'https://github.com/michaelloistl/ContextLabel.git', :tag => s.version }

    s.ios.deployment_target = '8.0'

    s.source_files = 'Source/*.{swift}'

    s.requires_arc = true
end

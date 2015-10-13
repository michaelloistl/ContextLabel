Pod::Spec.new do |s|
    s.name = 'ContextLabel'
    s.version = '0.2.0'
    s.license = 'MIT'
    s.summary = 'A simple to use drop in replacement for UILabel written in Swift that provides automatic detection of links such as URLs, twitter style usernames and hashtags.'
    s.authors = { 'Michael Loistl' => 'michael@aplo.co' }
    s.source = { :git => 'https://github.com/michaelloistl/ContextLabel.Swift.git', :tag => s.version }

    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.9'
    s.watchos.deployment_target = '2.0'

    s.source_files = 'ContextLabel/*.{swift}'

    s.requires_arc = true
end
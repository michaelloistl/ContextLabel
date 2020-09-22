Pod::Spec.new do |s|
    s.name = 'ContextLabel'
    s.version = '1.5.1'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.summary = 'A simple to use drop in replacement for UILabel'
    s.description = 'A simple to use drop in replacement for UILabel written in Swift that provides automatic detection of links such as URLs, twitter style usernames and hashtags.'
    s.authors = { 'Michael Loistl' => 'michael@aplo.io' }
    s.homepage = "https://github.com/MalcolmnDEV/ContextLabel"
    s.source = { :git => 'https://github.com/MalcolmnDEV/ContextLabel.git', :tag => s.version }
    s.ios.deployment_target = '11.0'
    s.source_files = 'Sources/*.{swift}'
    s.requires_arc = true
end

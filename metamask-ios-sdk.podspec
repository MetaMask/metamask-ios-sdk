Pod::Spec.new do |s|
    s.name             = 'metamask-ios-sdk'
    s.version          = '0.1.0'
    s.summary          = 'MetaMask SDK for iOS'
    s.homepage         = 'https://github.com/MetaMask/metamask-ios-sdk'
    s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
    s.author           = { 'MetaMask' => 'MetaMask' }
    s.source           = { :git => 'https://github.com/MetaMask/metamask-ios-sdk.git', :tag => s.version.to_s }
    s.ios.deployment_target = '14.0'
    s.swift_version = '5.7'
    s.source_files = 'Sources/metamask-ios-sdk/**/*'
  end
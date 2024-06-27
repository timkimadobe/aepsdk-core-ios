Pod::Spec.new do |s|
    s.name             = "AEPTestUtils"
    s.version          = "1.2.3"
    s.summary          = "Adobe Experience Platform test utilities for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."
  
    s.description      = <<-DESC
                         The Adobe Experience Platform test utilities enable easier testing of Adobe Experience Platform Mobile SDKs.
                         DESC
  
    s.homepage         = "https://github.com/adobe/aepsdk-core-ios"
    s.license          = 'Apache V2'
    s.author           = "Adobe Experience Platform SDK Team"
    s.source           = { :git => "https://github.com/adobe/aepsdk-core-ios", :tag => s.version.to_s }
    
    s.ios.deployment_target = '12.0'
    s.tvos.deployment_target = '12.0'
  
    s.swift_version = '5.1'
  
    s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  
    s.frameworks   = 'XCTest'
  
    s.source_files = [
        'AEPServices/Mocks/PublicTestUtils/**/*.swift',
        'AEPCore/Mocks/PublicTestUtils/**/*.swift'
    ]
    
    s.dependency 'AEPCore', '>= 4.5.6', '< 6.0.0'
    s.dependency 'AEPServices', '>= 4.5.6', '< 6.0.0'
  end
  
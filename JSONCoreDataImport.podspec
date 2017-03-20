Pod::Spec.new do |s|
  s.name             = 'JSONCoreDataImport'
  s.version          = '1.0'
  s.summary          = 'Simply import your data'
 
  s.homepage         = 'https://github.com/hours-alone/JSONCoreDataImport'
  s.license 		 = { :type => "MIT", :file => "LICENSE" }
  s.author           = { 'Joey Barbier' => 'joey.barbier@icloud.com' }
  s.source           = { :git => 'https://github.com/hours-alone/JSONCoreDataImport.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '8.0'
  s.source_files = 'JSONCoreDataImport/Source/*.swift'

  s.framework = "UIKit"
  s.framework = "CoreData"
  s.dependency 'SwiftyJSON', '~> 3.1'
  s.dependency 'Alamofire', '~> 4.4.0'

end
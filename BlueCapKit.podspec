Pod::Spec.new do |spec|

  spec.name              = "BlueCapKit"
  spec.version           = "0.4.0"
  spec.summary           = "BlueCap is Swift  CoreBluetooth and much more."

  spec.homepage          = "https://github.com/troystribling/BlueCap"
  spec.license           = { :type => "MIT", :file => "LICENSE" }
  spec.documentation_url = "https://github.com/troystribling/BlueCap"

  spec.author             = { "Troy Stribling" => "me@troystribling.com" }
  spec.social_media_url   = "http://twitter.com/troystribling"

  spec.ios.deployment_target = "9.0"
  spec.tvos.deployment_target = "9.0"

  spec.cocoapods_version  = '>= 1.1'

  spec.source             = { :git => "https://github.com/troystribling/BlueCap.git", :tag => "#{spec.version}" }
  spec.ios.source_files   = "BlueCapKit/**/*.swift"
  spec.tvos.source_files  = "BlueCapKit/**/*.swift"
  spec.tvos.exclude_files = "BlueCapKit/External/FutureLocation/**/*.swift"
  spec.ios.frameworks     = "CoreBluetooth", "CoreLocation"
  spec.tvos.frameworks    = "CoreBluetooth"

end

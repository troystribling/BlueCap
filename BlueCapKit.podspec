#
#  Be sure to run `pod spec lint BlueCap.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "BlueCapKit"
  s.version      = "0.1.0"
  s.summary      = "BlueCap provides a swift wrapper around CoreBluetooth and much more."
  s.description  = <<-DESC
BlueCap provides a Swift wrapper around CoreBluetooth that replaces protocol implementaions with futures.
It also provides connection events for connect, disconnect and timeout; service scan and read/write timeouts;
a DSL for specification of GATT profiles and characteristic profile types encapsulating serilaizaion/deserailization
                   DESC

  s.homepage     = "https://github.com/troystribling/BlueCap"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Troy Stribling" => "troy.stribling@gmail.com" }
  s.social_media_url   = "http://twitter.com/troystribling"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "http://troystribling/BlueCap.git", :tag => "#{s.version}" }
  s.source_files  = "BlueCapKit/**/*.swift"
  s.frameworks = "CoreBluetooth", "CoreLocation"

end

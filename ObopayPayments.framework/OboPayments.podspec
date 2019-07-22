#
#  Be sure to run `pod spec lint obopayspec.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name           = "OboPayments"
  s.version        = "0.1.0"
  s.summary        = "Obopay suite of SDKs."
  s.description    = "Obopay payments iOS SDK provides seamless integration to business iOS app to offer Obopay payment services to it’s customers."
  s.homepage       = "https://www.obopay.com"
  s.swift_versions = "4.2"
  s.license        = {
    :type => "MIT",
    :file => "LICENSE"
  }
  s.author         = "Obopay Mobile Techonlogies Pvt. Ltd."
  s.platform       = :ios, "10.0"
  s.source         = {
    :git => "https://github.com/obopay/payments-sdk-ios.git",
    :tag => "0.1.0"
  }
  s.source_files   = "obopaypayments/**/*.swift"
  s.framework      = 'Foundation'

end

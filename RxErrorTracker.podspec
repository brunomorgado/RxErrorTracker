Pod::Spec.new do |s|
  s.name             = 'RxErrorTracker'
  s.version          = '1.0.0'
  s.summary          = 'An RxSwifty approach to error handling.'
  s.description      = <<-DESC
RxErrorTracker provides a clean, integrated and easy to use approach to error handling. It is based on RxSwift and represents an observable sequence of errors Rx style. The main benefit is to enable a single point of entry for dealing with the multiple errors that applications need to handle.
                       DESC
  s.homepage         = 'https://github.com/brunomorgado/RxErrorTracker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bruno Morgado' => 'brunofcmorgado@gmail.com' }
  s.source           = { :git => 'https://github.com/brunomorgado/RxErrorTracker.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/bfcmorgado'

  s.ios.deployment_target = '8.0'
  s.source_files = 'RxErrorTracker/Classes/**/*'
  s.dependency 'RxSwift', '~> 2.6'
  s.dependency 'RxCocoa', '~> 2.6'
end

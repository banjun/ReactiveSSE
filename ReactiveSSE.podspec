Pod::Spec.new do |s|
  s.name             = 'ReactiveSSE'
  s.version          = '0.3.0'
  s.summary          = 'Server Sent Events (SSE) parser operators for ReactiveSwift'
  s.description      = <<-DESC
Server Sent Events (SSE) parser operators for ReactiveSwift.
You can observe event streams sent via Server Sent Events (SSE).
                       DESC
  s.homepage         = 'https://github.com/banjun/ReactiveSSE'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'banjun' => 'banjun@gmail.com' }
  s.source           = { :git => 'https://github.com/banjun/ReactiveSSE.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/banjun'
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.source_files = 'ReactiveSSE/Classes/**/*'
  s.dependency 'ReactiveSwift', '~> 4.0'
  s.dependency 'FootlessParser', '~> 0.5'
end

Pod::Spec.new do |s|
  s.name             = 'SSPPullToRefresh'
  s.version          = '0.1.13'
  s.summary          = 'General classes for "Pull-To-Refresh" concept customisation'

  s.description      = <<-DESC
This general classes provide for client the possbility to make own derived implementations
                       DESC

  s.homepage         = 'https://github.com/Sergey-Lomov/SSPPullToRefresh'
  s.author           = { 'Sergey Lomov' => 'SSpirit10000@gmail.com' }
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.source           = { :git => 'https://github.com/Sergey-Lomov/SSPPullToRefresh.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = '**/*.swift'

end

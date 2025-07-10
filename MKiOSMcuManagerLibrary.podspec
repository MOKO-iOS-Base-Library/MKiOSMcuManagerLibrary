Pod::Spec.new do |s|
  s.name             = 'MKiOSMcuManagerLibrary'
  s.version          = '0.0.3'
  s.summary          = 'iOS Mcu upgrade component library of MOKO.'

  s.description      = <<-DESC
  A library for managing MCU firmware upgrades over BLE.
                       DESC

  s.homepage         = 'https://github.com/MOKO-iOS-Base-Library/MKiOSMcuManagerLibrary'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'aadyx2007@163.com' => 'aadyx2007@163.com' }
  s.source           = { :git => 'https://github.com/MOKO-iOS-Base-Library/MKiOSMcuManagerLibrary.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '14.0'
  
  s.source_files = "Sources/**/*.{swift, h}"
  
  s.dependency 'iOSMcuManagerLibrary'
end

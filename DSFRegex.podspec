Pod::Spec.new do |s|
  s.name                 = "DSFRegex"
  s.version              = "3.1.0"
  s.summary              = "A Swift based Regex class"
  s.description          = <<-DESC
    A Swift regex class abstracting away the complexities of NSRegularExpression, NSRange and Swift Strings
  DESC
  s.homepage             = "https://github.com/dagronf"
  s.license              = { :type => "MIT", :file => "LICENSE" }
  s.author               = { "Darren Ford" => "dford_au-reg@yahoo.com" }
  s.source               = { :git => "https://github.com/dagronf/DSFRegex.git", :tag => s.version.to_s }
  s.platforms            = { :ios => "12.0", :tvos => "12.0", :osx => "10.13", :watchos => "4.0" }
  s.source_files         = 'Sources/DSFRegex/**/*.swift'
  s.swift_versions       = ['5.3', '5.4', '5.5', '5.6', '5.7']
end

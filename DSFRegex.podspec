Pod::Spec.new do |s|
  s.name         = "DSFRegex"
  s.version      = "1.1"
  s.summary      = "A Swift based Regex class"
  s.description  = <<-DESC
    A Swift based Regex class
  DESC
  s.homepage     = "https://github.com/dagronf"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Darren Ford" => "dford_au-reg@yahoo.com" }
  s.social_media_url   = ""
  s.source       = { :git => ".git", :tag => s.version.to_s }
  s.subspec "Core" do |ss|
    ss.source_files  = "Sources/DSFRegex/**/*.swift"
  end

  s.swift_version = "5.0"
end

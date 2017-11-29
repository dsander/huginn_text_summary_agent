# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "huginn_text_summary_agent"
  spec.version       = '0.1'
  spec.authors       = ["Dominik Sander"]
  spec.email         = ["git@dsander.de"]

  spec.summary       = %q{The huginn_text_summary_agent summarized a given text using the epitome gem.}

  spec.homepage      = "https://github.com/dsander/huginn_text_summary_agent"

  spec.license       = "MIT"


  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "huginn_agent"
  spec.add_runtime_dependency "epitome", "~> 0.3.1"
end

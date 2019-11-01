
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ruby_pkg/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby_pkg"
  spec.version       = RubyPkg::VERSION
  spec.authors       = ["Liam Cole"]
  spec.email         = ["liam@liamiam.com"]

  spec.summary       = %q{Simple ruby package installer/remover for linux/macos}
  spec.description   = %Q{#{RubyPkg::DESC}\n\nWhat's new:\n#{RubyPkg::WHATS_NEW}}
  spec.homepage      = "https://github.com/liamcoal/ruby_pkg"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license = 'GPL-3.0-only'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "json", "~> 2.1"
end

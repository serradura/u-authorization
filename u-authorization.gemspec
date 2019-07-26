lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'authorization'

Gem::Specification.new do |spec|
  spec.name         = 'u-authorization'
  spec.version      = Authorization::VERSION
  spec.authors      = ['Rodrigo Serradura']
  spec.email        = ['rodrigo.serradura@gmail.com']

  spec.summary      = 'Authorization library and role managment'
  spec.description  = 'Simple authorization library and role managment for Ruby.'
  spec.homepage     = 'https://github.com/serradura/u-authorization'
  spec.license      = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end

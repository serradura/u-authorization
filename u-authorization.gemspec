require_relative 'authorization'

Gem::Specification.new do |s|
  s.name         = 'u-authorization'
  s.summary      = 'Authorization library and role managment'
  s.description  = 'Simple authorization library and role managment for Ruby.'
  s.version      = Authorization::VERSION
  s.licenses     = ['MIT']
  s.platform     = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.2.2'

  s.files        = ['authorization.rb', 'u-authorization.rb']
  s.require_path = '.'

  s.author    = 'Rodrigo Serradura'
  s.email     = 'rodrigo.serradura@gmail.com'
  s.homepage  = 'https://gist.github.com/serradura/7d51b979b90609d8601d0f416a9aa373'
end

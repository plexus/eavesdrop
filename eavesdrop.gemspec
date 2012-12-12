Gem::Specification.new do |s|
  s.name        = 'eavesdrop'
  s.version     = '0.1.0'
  s.platform    = Gem::Platform::RUBY
  s.author      = 'Arne Brasseur'
  s.email       = 'arne.brasseur@gmail.com'
  s.summary     = 'Event listener DSL'
  s.description = 'Decouple your code declaritively.'

  s.files         = ['lib/eavesdrop.rb']
  s.test_files    = ['spec/eavesdrop_spec.rb']
  s.require_path  = 'lib'

  s.add_development_dependency('rspec', ["~> 2.0"])
end

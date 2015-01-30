# -*- encoding: utf-8 -*-
require File.expand_path('../lib/circle/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Robert Rouse"]
  gem.email         = ["robert@theymaybecoders.com"]
  gem.description   = %q{Gem for maintaining friendships in ActiveRecord}
  gem.summary       = %q{Gem for maintaining friendships in ActiveRecord}
  gem.homepage      = "https://github.com/theymaybecoders/circle"

  gem.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "circle"
  gem.require_paths = ["lib"]
  gem.version       = Circle::VERSION

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "fabrication"
  gem.add_development_dependency "shoulda-matchers"
  gem.add_development_dependency "database_cleaner"
  gem.add_development_dependency "simplecov"

  gem.add_dependency "activerecord", '~> 4'
end

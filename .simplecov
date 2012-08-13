SimpleCov.start do
  add_filter "spec/schema.rb"
  add_filter "lib/circle/version.rb"
  add_filter "spec/fabricators/"
  add_filter "lib/circle/engine.rb"
end
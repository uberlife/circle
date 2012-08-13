require "circle/version"

if defined?(Rails)
  require "circle/railtie"
end

require "circle/circle"

ActiveRecord::Base.send(:include, Circle)
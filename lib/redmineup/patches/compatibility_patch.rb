if Redmine::VERSION.to_s < "6"
  require 'redmineup/patches/compatibility/sprite_patch'
end
require 'redmineup/patches/compatibility/routing_mapper_patch'

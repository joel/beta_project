require 'active_support'
require 'active_support/dependencies/autoload'

 module Foo
   extend ActiveSupport::Autoload

   eager_autoload do
     autoload :Bar
   end
 end

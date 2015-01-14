require 'bogo/version'

module Bogo
  autoload :AnimalStrings, 'bogo/animal_strings'
  autoload :Constants, 'bogo/constants'
  autoload :Lazy, 'bogo/lazy'
  autoload :Memoization, 'bogo/memoization'
  autoload :Smash, 'bogo/smash'
end

# Always load smash
require 'bogo/smash'

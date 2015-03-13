require 'bogo/version'

module Bogo
  autoload :AnimalStrings, 'bogo/animal_strings'
  autoload :Constants, 'bogo/constants'
  autoload :EphemeralFile, 'bogo/ephemeral_file'
  autoload :Lazy, 'bogo/lazy'
  autoload :Memoization, 'bogo/memoization'
  autoload :PriorityQueue, 'bogo/priority_queue'
  autoload :Smash, 'bogo/smash'
  autoload :Utility, 'bogo/utility'
end

# Always load smash
require 'bogo/smash'

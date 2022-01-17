require "bogo/version"

module Bogo
  autoload :AnimalStrings, "bogo/animal_strings"
  autoload :Constants, "bogo/constants"
  autoload :EphemeralFile, "bogo/ephemeral_file"
  autoload :Lazy, "bogo/lazy"
  autoload :Logger, "bogo/logger"
  autoload :Memoization, "bogo/memoization"
  autoload :PriorityQueue, "bogo/priority_queue"
  autoload :Retry, "bogo/retry"
  autoload :Smash, "bogo/smash"
  autoload :Stack, "bogo/stack"
  autoload :Utility, "bogo/utility"
end

# Always load smash
require "bogo/smash"

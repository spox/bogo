# v0.2.6
* [Smash] Use Hash#dig if available to speed up access (GH-5)

# v0.2.4
* [Memoization] Refactor to remove Ruby 2.3 deprecation warnings

# v0.2.2
* [Memoization] Add #memoized? helper

# v0.2.0
* [Lazy] Map #attributes to #data when flagged always clean

# v0.1.32
* [AnimalStrings] Add support for leading and non-leading upcase

# v0.1.30
* [Lazy] Inspect data prior to checksum to prevent circular issues
* [Retry] Support custom block to determine retry

# v0.1.28
* [Smash] Ensure valid data type on checksum generation
* [Retry] Add new retry abstract and concrete subclasses

# v0.1.26
* [Smash] Fix behavior around accessing falsey values

# v0.1.24
* [Lazy] Allow multiple results from coercion output

# v0.1.22
* Fix CONNECT requests for HTTPS endpoints to properly include port

# v0.1.20
* Add lazy proxy support monkey patch for http library
* [Lazy] Return default values when no data has been loaded

# v0.1.18
* [PriorityQueue] Fix highscore sorting

# v0.1.16
* [EphemeralFile] Add new EphemeralFile class

# v0.1.14
* [PriorityQueue] Add PriorityQueue#include? helper method
* [PriorityQueue] Wrap sorting with synchronization
* [Constants] Remove pre-check for constant (force load)

# v0.1.12
* Support multiple item push on `PriorityQueue`

# v0.1.10
* Add `Lazy#always_clean!` to remove attribute state
* Add `PriorityQueue`

# v0.1.8
* Use `#to_smash` to for duping to preserve types
* Force type on merges

# v0.1.6
* Add utility module for easy direct access to helpers
* Add support for automatic key conversion (:snake or :camel) on `Smash#to_smash`

# v0.1.4
* Add constant helpers
* Add support for freezing Smashes

# v0.1.2
* Add initial spec coverage
* Always load `Bogo::Smash`
* Add support for global memoization
* Auto default lazy data on init

# v0.1.0
* Initial release

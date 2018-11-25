# Bogo

A collection of helper libraries. What's in the box:

## Animal strings

Convert camel cased strings to snake case or snake cased strings
to camel case:

```ruby
require 'bogo'

class Stringer
  include Bogo::AnimalStrings
end

str = Stringer.new
puts str.snake('CamelCasedString')
puts str.camel('snake_cased_string')
```

## Smash

Extension of the Hash class. It makes use of the `hashie` library and
adds a few extra features as well:

Included hashie modules:

* Hashie::Extensions::IndifferentAccess
* Hashie::Extensions::MergeInitializer
* Hashie::Extensions::DeepMerge
* Hashie::Extensions::Coercion

Added extras:

### Conversion

Will convert from `Hash` to `Smash`. This conversion includes `Hash`
types found within `Array`s:

```ruby
require 'bogo'

inst = {:a => 1, 'b' => 2, :c => [{:z => true}]}.to_smash
puts inst[:a]
puts inst['c'].first['z']
```

and we can convert from `Smash` to `Hash` as well:

```ruby
require 'bogo'

inst = {:a => 1, 'b' => 2, :c => [{:z => true}]}.to_smash
puts inst.class
puts inst[:c].first.class
inst = inst.to_hash
puts inst.class
puts inst['c'].first.class
```

### Path Walking

Values can be returned if given a path. If the path does not exist
a `nil` will be return instead of raising an exception:

```ruby
require 'bogo'

inst = Smash.new(:a => {:b => {:c => {:d => 1}}})
puts inst.get(:a, :b, :c, :d)
puts inst.get(:a, :c, :x, :z)
```

### Default value on missing path

Use `#fetch` to provide default value if path does not exist. The
last value in the list will be used as the returned value:

```ruby
require 'bogo'

inst = Smash.new(:a => 1)
puts inst.fetch(:b, :c, 2)
```

### Set value at path

Set deeply nested values by providing the path. The last value
in the list will be set:

```ruby
require 'bogo'

inst = Smash.new
inst.set(:a, :b, :c, :d, :e, 1)
puts inst.get(:a, :b, :c, :d, :e)
```

### Checksums

Checksum will generate a new `Smash` instance with sorted keys
and then generate a SHA256 digest:

```ruby
require 'bogo'

puts Smash.new(:a => 1, :b => 2, :c => 3).checksum
puts Smash.new(:c => 3, :b => 2, :a => 1).checksum
```

### Freezing

Freeze entire smash structure:

```ruby
require 'bogo'

inst = {:a => 'hi', :b => {:c => 'bye'}}.to_smash(:freeze)
puts inst[:a].frozen? 'Frozen' : 'Thawed'
puts inst[:b].frozen? 'Frozen' : 'Thawed'
puts inst[:b][:c].frozen? 'Frozen' : 'Thawed'
```

### Arrays

The `#to_smash` helper is also attached to `Array` to
fully convert an Arrays internals to Smashes

```ruby
require 'bogo'

puts [{:a => 1}].to_smash.first.class.name
```

## Constants

Turn a string into a constant:

```ruby
require 'bogo'

const = Object.new.extend(Bogo::Constants)
p const.constantize('Bogo::Constants')
```

Get the namespace of a constant:

```ruby
require 'bogo'

const = Object.new.extend(Bogo::Constants)
p const.namespace('Bogo::Constants')
```

## Memoization

Memoization helpers for thread and object local, thread local,
and global memoization:

```ruby
require 'bogo'

class Memo
  include Bogo::Memoization

  def object_value(provided_value)
    memoize(:value){ provided_value }
  end

  def thread_value(provided_value)
    memoize(:value, true){ provided_value }
  end

  def global_value(provided_value)
    memoize(:value, :global){ provided_value }
  end
end

obj1 = Memo.new
obj2 = Memo.new

obj1.object_value('ohai')
obj1.thread_value('obai')
obj1.global_value('ohey')

puts '--- obj1 start'
puts obj1.object_value('fubar')
puts obj1.thread_value('fubar')
puts obj1.global_value('fubar')
puts '--- obj1 end'
puts '--- obj2 start'
puts obj2.object_value('fubar')
puts obj2.thread_value('fubar')
puts obj2.global_value('fubar')
puts '--- obj2 end'
```

## Lazy

Easily define attributes within a class. Provides
type checking, coercion, and callback integration
for dependencies and missing values.

```ruby
require 'bogo'

class MyData
  include Bogo::Lazy

  attribute :name, String, :default => 'MyData'
  attribute :data_id, [String, Numeric]
  attribute :count, Float, :coerce => lambda{|v| v.to_f}
  attribute :remote_id, Integer, :depends => :remote_loader
  attribute :stuff, String

  on_missing :load_things

  def remote_loader
    data[:remote_id] = 42
  end

  def load_things
    data[:stuff] = 'ALL THE THINGS'
  end
end

data = MyData.new

puts data.name
data.name = 'New name!'
puts data.name
data.data_id = 1
puts data.data_id
data.data_id = 'one'
puts data.data_id
begin
  data.data_id = :one
rescue TypeError => e
  puts "#{e.class}: #{e}"
end
data.count = '1'
p data.count
puts data.remote_id
puts data.stuff
p data.dirty?(:name)
p data.data_id
p data.data
p data.dirty
p data.attributes
p data.dirty?
data.valid_state
p data.dirty?
p data.data
```

## PriorityQueue

Queue items based on a given score. Score can be provided as a
numerical value, or as the result of a block. By default, the
item with the lowest score has the highest priority.


```ruby
require 'bogo'

q = Bogo::PriorityQueue.new
q.push('a', 3)
q.push('b', 1)
puts q.pop
```

This will print "b" as it has the lowest score (highest priority). If
a high score is prefered to designate highest priority, that can  be
set when initializing the instance of the queue:

```ruby
require 'bogo'

q = Bogo::PriorityQueue.new(:highscore)
```

Scores can also be provided as blocks which will be evaluated prior
to `#pop`:

```ruby
require 'bogo'

q = Bogo::PriorityQueue.new(:highscore)
q.push('a'){ Time.now.to_i }
q.push('b', Time.now.to_i)
sleep(1)
puts q.pop
```

This will print "a" as its score will be higher when popped.

## EphemeralFile

This is just like a Tempfile (this is just a subclass) except that
it will delete itself when closed.

```ruby
require 'bogo'

e_file = Bogo::EphemeralFile.new('bogo')
path = e_file.path
puts "File exists: #{File.exists?(path)}"
e_file.close
puts "File exists: #{File.exists?(path)}"
```

## Retry

Retry an action until success or maximum number of attempts
has been reached.

### `Bogo::Retry`

This is an abstract class and does not provide actual retry
functionality. Custom concrete implementations must define a
`#wait_on_failure` method that provides the number of seconds
to wait until the next attempt.

The `Bogo::Retry` does provide an easy way to generate a
retry instance:

```ruby
Bogo::Retry.build(:flat, :wait_interval => 2) do
  puts 'This is run within a Bogo::Retry::Flat instance!'
end
```

If the value of the action is required, disable auto run
and explicitly start the retry:

```ruby
value = Bogo::Retry.build(:flat, :auto_run => false) do
  puts 'This is run within a Bogo::Retry::Flat instance!'
  42
end.run!
```

A block can also be provided to `run!` which will be called
when an exception is rescued to determine if the request should
be retried:

```ruby
value = Bogo::Retry.build(:flat, :auto_run => false) do
  puts 'This is run within a Bogo::Retry::Flat instance!'
  42
end.run! do |exception|
  exception.is_a?(ErrorThatShouldBeRetried)
end
```

#### `Bogo::Retry::Flat`

The flat retry implementation will always wait the `wait_interval`
value before retry.

* `:wait_interval` - Numeric (default: 5)

#### `Bogo::Retry::Linear`

The linear retry implementation will increase the wait time between
retries at a linear rate before retry:

* `:wait_interval` - Numeric (default: 5)

#### `Bogo::Retry::Exponential`

The exponential retry implementation will increase the wait time
between retries at an exponential rate before retry:

* `:wait_interval` - Numeric (default: 5)
* `:wait_exponent` - Numeric (default: 2)

## `Bogo::Logger`

This is a wrapped stdlib Logger instance to provide thread-safe
access for logging. It includes a `Bogo::Logger#named` method for
creating sub-loggers.

```ruby
require 'bogo'

base = Bogo::Logger.new
base.progname = 'base'
base.info 'test'

sub = base.named(:sub)
sub.info 'test'
```

### `Bogo::Logger::Helpers`

Adds a `#logger` method when included which provides access to the
global logger. Name can be customized using `.logger_name`.

```ruby
require 'bogo'

class Fubar
  class Thing
    include Bogo::Logger::Helpers
    logger_name(:thing)

    def test
      logger.info "test"
    end
  end
end
```

# Info
* Repository: https://github.com/spox/bogo

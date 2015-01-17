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

## Info
* Repository: https://github.com/spox/bogo
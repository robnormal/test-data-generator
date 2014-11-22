class HashAppendable < Hash
  def <<(pair)
    key, value = *pair
    self[key] = value
  end
end

# choose random element from an Enumerable
require 'forgery'
def rand_in(xs)
  xs.to_a.sample
end

# random integer between min and max _inclusively_
def rand_between(min, max)
  rand(max - min + 1) + min
end


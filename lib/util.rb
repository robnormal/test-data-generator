class HashAppendable < Hash
  def <<(pair)
    key, value = *pair
    self[key] = value
  end
end

def hash_subset(hash, keys)
  keys.inject({}) { |h, k| h[k] = hash[k] }
end

# choose random element from an Enumerable
def rand_in(xs)
  xs.to_a.sample
end

# random integer between min and max _inclusively_
def rand_between(min, max)
  rand(max - min + 1) + min
end


class HashAppendable < Hash
  def <<(pair)
    key, value = *pair
    self[key] = value
  end
end

class Maybe
  def nothing?
    @is_nothing
  end

  def from_just
    if @is_nothing
      raise('Cannot call from_just() on Nothing')
    else
      @value
    end
  end

  def fmap(&blk)
    if nothing? then self else Maybe.just(blk.call @value) end
  end

  def into(&blk)
    if nothing? then self else blk.call @value end
  end

  def self.just(x)
    self.new(false, x)
  end

  def self.nothing
    self.new(true, nil)
  end

  private
  def initialize(is_nothing, value)
    @is_nothing = is_nothing
    @value = value
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


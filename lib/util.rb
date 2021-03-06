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

  # true if both are nothing, or if both contain same value
  def ==(m)
    if nothing?
      m.nothing?
    elsif m.nothing?
      false
    else
      from_just == m.from_just
    end
  end

  def fmap(&blk)
    if nothing?
      self
    else
      Maybe.just(blk.call @value)
    end
  end

  def into(&blk)
    if nothing?
      self
    else
      blk.call @value
    end
  end

  def check
    if nothing?
      false
    else
      yield @value
    end
  end

  def self.just(x)
    self.new(false, x)
  end

  def self.nothing
    self.new(true, nil)
  end

  def self.maybe(x)
    if x.nil? then Maybe.nothing else Maybe.just x end
  end

  private
  def initialize(is_nothing, value)
    @is_nothing = is_nothing
    @value = value
  end
end

def hash_subset(hash, keys)
  h = {}
  keys.each { |k| h[k] = hash[k] }
  h
end

def list_bind(list, &blk)
  list.map(&blk).flatten(1)
end

def fmap(obj, &blk)
  if obj.is_a? Hash
    h = {}
    obj.each { |k, v| h[k] = blk.call(v) }
    h
  else
    obj.map(&blk)
  end
end

def fmap_with_keys(obj, &blk)
  h = {}
  obj.each { |k, v| h[k] = blk.call(k, v) }
  h
end

# choose random element from an Enumerable
def rand_in(xs)
  xs.to_a.sample
end

# random integer between min and max _inclusively_
def rand_between(min, max)
  rand(max - min + 1) + min
end


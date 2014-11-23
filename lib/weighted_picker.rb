class WeigtedPicker
  # @param weights [Hash{Object => Numeric}]
  def initialize(weights)
    @weights = weights

    # we check a random number against @thresholds to pick element
    @thresholds = []
    thresh = 0
    @weights.each do |elem, weight|
      thresh += weight
      @thresholds << [elem, weight]
    end

    # we pick our random number to be less than this
    @upper_threshold = thresh
  end

  # random table, weighted by the max number of rows
  def pick
    r = rand(@upper_threshold)
    @thresholds.find { |value, x| r < x }.first
  end
end


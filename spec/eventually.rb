RSpec::Matchers.define :eventually do |matcher|
  match do |block|
    tries = 0
    while tries < 10000
      if matcher.supports_block_expectations? && matcher.matches?(actual)
        break
      elsif matcher.matches?(actual.call)
        break
      end
        
      tries += 1
    end

    tries < 10000
  end

  def supports_block_expectations?; true end
end



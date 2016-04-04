class SearchCache
  attr_reader :counter

  def initialize()
    @counter = nil
    @hash = {}
  end

  def invalidate(cache_counter)
    @counter = cache_counter
    @hash = {}
  end

  def valid?(cache_counter)
    @counter == cache_counter
  end

  def fetch(key)
    if @hash.has_key? key
      value = @hash[key]
    else
      value = yield

      @hash[key] = value
    end

    value
  end
end

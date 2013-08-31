class FrequentItems
  def initialize length=10, keys
    @length = length
    @keys = keys
  end

  def add item
    if $redis.zcard(redis_key()) < @length #fill the rank
      return $redis.zincrby(redis_key(), 1, item)
    end

    score = $redis.zrank(redis_key(), item)

    unless score # new item
      return $redis.zincrby(redis_key(), 1, item) if decrease_all_by_1() > 0
    else # already exists
      return $redis.zincrby(redis_key(), 1, item)
    end
  end

  def get_scores score = 0
    $redis.zrevrange(redis_key(), 0, -1, :with_scores => true)
  end

  private

  def decrease_all_by_1
    all = $redis.zrange(redis_key(), 0, -1)
    $redis.multi do
      all.each do |item|
        $redis.zincrby(redis_key(), -1, item)
      end
    end
    cleanup_list()
  end

  # Delete items with score 0
  def cleanup_list
    $redis.zremrangebyscore(redis_key(), 0, 0)
  end

  def redis_key
    "#{@keys}:trend"
  end

end
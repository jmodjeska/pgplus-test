class Scorekeeper
  def initialize
    @scorecard = { pass: 0, fail: 0, err: 0 }
  end

  def add(scores)
    scores.each do |type, count|
      @scorecard[type] += count
    end
  end

  def report
    return @scorecard
  end
end

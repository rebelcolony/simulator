class HyperSimulation < ActiveRecord::Base
  validates_uniqueness_of :country, scope: [:since, :up_to, :interval_min, :interval_max, :market_type, :rule]

  serialize :results, Hash

  FIRST_STEP = 0.1
  SECOND_STEP = 0.01

  FULL_RANGES = [
    1..6, 1..7, 1..8, 1..9, 1..10, 1..11,  1..12,  1..14,  1..16,  1..18,  1..20,
    2..6, 2..7, 2..8, 2..9, 2..10, 2..11,  2..12,  2..14,  2..16,  2..18,  2..20,
    3..6, 3..7, 3..8, 3..9, 3..10, 3..11,  3..12,  3..14,  3..16,  3..18,  3..20,
    4..6, 4..7, 4..8, 4..9, 4..10, 4..11,  4..12,  4..14,  4..16,  4..18,  4..20,
    5..6, 5..7, 5..8, 5..9, 5..10, 5..11,  5..12,  5..14,  5..16,  5..18,  5..20,
          6..7, 6..8, 6..9, 6..10, 6..11,  6..12,  6..14,  6..16,  6..18,  6..20,
                7..8, 7..9, 7..10, 7..11,  7..12,  7..14,  7..16,  7..18,  7..20,
                      8..9, 8..10, 8..11,  8..12,  8..14,  8..16,  8..18,  8..20,
                            9..10, 9..11,  9..12,  9..14,  9..16,  9..18,  9..20,
                                   10..11, 10..12, 10..14, 10..16, 10..18, 10..20,
                                           11..12, 11..14, 11..16, 11..18, 11..20
  ]

  def simulate!
    $start = Time.now

    out :hyper, "Preparing for HyperSimulation:"
    out :hyper, "FROM #{since} TO #{up_to}"
    out :hyper, "INTERVAL #{interval_min}..#{interval_max}"
    out :hyper, "#{rule.upcase} rule - #{Venue::COUNTRY_IDS[country].upcase} - #{MarketType.find(market_type)[:internal].upcase}"

    out :hyper, "Looking for valid race days from #{since} TO #{up_to}"

    @races = (since..up_to).inject([]) do |res, date|
      race = RaceDay.find_by_id(RaceDay.race_day_hash[date.to_s])
      if race
        if !race.cached
          out :hyper, "Cannot use RaceDay #{race.id} (#{race.date}), it isn't cached"
          next res
        end

        if !race.imported
          out :hyper, "Cannot use RaceDay #{race.id} (#{race.date}), it isn't imported"
          next res
        end

        res << race.id
        res
      else
        out :hyper, "Cannot find RaceDay with date #{date}"
        next res
      end
    end

    out :hyper, "Found #{@races.count} valid race days from #{since} TO #{up_to} (missing #{(since..up_to).to_a.size - @races.count})"

    # Get first results (broad strokes)
    first_result = get_results(interval_min..interval_max, FIRST_STEP)

    # Second pass
    steps = (first_result[:hit_rate][0] - FIRST_STEP).round(2)..(first_result[:hit_rate][0] + FIRST_STEP).round(2)
    self.results[:hit_rate] = get_results(steps, SECOND_STEP, [:hit_rate], [first_result[:hit_rate][1]])

    steps = (first_result[:points][0] - FIRST_STEP).round(2)..(first_result[:points][0] + FIRST_STEP).round(2)
    self.results[:points] = get_results(steps, SECOND_STEP, [:points], [first_result[:points][1]])

    steps = (first_result[:strike_rate][0] - FIRST_STEP).round(2)..(first_result[:strike_rate][0] + FIRST_STEP).round(2)
    self.results[:strike_rate] = get_results(steps, SECOND_STEP, [:strike_rate], [first_result[:strike_rate][1]])

    out :hyper, "SUCCESS - Finished HyperSimulation"

    save
  end

  def get_results(steps, step, metrics = [:hit_rate, :points, :strike_rate], ranges = FULL_RANGES)
    i = 0
    @simulations = []

    steps_array = steps.step(step).map { |a| a.round(2) }.to_a

    steps_array.map do |interval|

      out :hyper, "#{(((i += 1) / steps_array.size.to_f) * 100).to_i}% - #{metrics.map {|m| m.to_s.upcase.split('_').first }.join('/')} - INTERVAL #{interval.inspect}"

      ranges.each do |range|
        @simulations << DateSimulation.new(
          since: since,
          up_to: up_to,
          interval: interval,
          range: range,
          rule: rule,
          races: @races,
          country: country,
          market_type: market_type,
          metrics: metrics
        ).simulate!
      end
    end

    result = {}

    # HIT RATE
    if metrics.include?(:hit_rate)
      maxed = get_max(:hit_rate, :return)
      result[:hit_rate] = [maxed.interval, maxed.range]
      out :hyper, "For interval #{step} STEP: Best HIT #{result[:hit_rate][0]}/#{result[:hit_rate][1].inspect} (#{maxed.hit_rate}%)}"
    end

    # POINTS
    if metrics.include?(:points)
      maxed = get_max(:return, :hit_rate)
      result[:points] = [maxed.interval, maxed.range]
      out :hyper, "For interval #{step} STEP: Best POINTS #{result[:points][0]}/#{result[:points][1].inspect} (#{maxed.return})"
    end

    # STRIKE RATE
    if metrics.include?(:strike_rate)
      maxed = get_max(:strike_rate, :hit_rate)
      result[:strike_rate] = [maxed.interval, maxed.range]
      out :hyper, "For interval #{step} STEP: Best STRIKE #{result[:strike_rate][0]}/#{result[:strike_rate][1].inspect} (#{maxed.strike_rate}%)"
    end

    result
  end

  def get_max(first_sort, second_sort)
    begin
    max_first = @simulations.collect(&first_sort).max
  rescue
    raise @simulations.inspect
  end
    maxed = @simulations.select { |a| a.send(first_sort) == max_first }
    max_second = maxed.collect(&second_sort).max

    if maxed.size == 1
      maxed.first
    else
      @simulations.select do |a|
        a.send(first_sort) == max_first and a.send(second_sort) == max_second
      end.first
    end
  end
end

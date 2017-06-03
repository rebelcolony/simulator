class HyperSimulation < ActiveRecord::Base
  validates_uniqueness_of :country, scope: [:since, :up_to, :interval_min, :interval_max, :market_type, :rule]

  serialize :results, Hash

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

    self.results = get_results

    out :hyper, "SUCCESS - Finished HyperSimulation"

    save
  end

  def get_results
    i = 0
    @simulations = []

    FULL_RANGES.each do |range|
      out :hyper, "#{(((i += 1) / FULL_RANGES.size.to_f) * 100).to_i}% - RANGE #{range.inspect}"

      results = Simulation.connection.select_all("
        SELECT interval, SUM(total) AS total, SUM(winners) AS winners, SUM(best_price) AS best_price, SUM(return) AS return, SUM(profit) AS profit, ROUND((COUNT(profit >= 0) * 100)::numeric / COUNT(*), 2) AS strike_rate
        FROM simulations
        WHERE race_day_id IN (#{@races.join(', ')})
        AND range_min = #{range.min}
        AND range_max = #{range.max}
        AND rule = '#{rule}'
        AND country = #{country}
        AND market_type = #{market_type}
        GROUP BY interval
        ORDER BY interval
      ")

      results.each do |result|
        simu = {
          interval: result['interval'],
          range: range,
          rule: rule,
          country: country,
          market_type: market_type,
          total: result['total'],
          winners: result['winners'],
          best_price: result['best_price'],
          return: result['return'],
          profit: result['profit'],
          strike_rate: result['strike_rate']
        }

        simu[:hit_rate] = (simu[:winners].to_f / simu[:total] * 100).round(2)
        simu[:hit_rate] = 0 if simu[:hit_rate].nan?

        @simulations << simu
      end
    end

    result = {}

    # HIT RATE
    maxed = get_max(:hit_rate, :return)
    result[:hit_rate] = [maxed[:interval], maxed[:range]]
    out :hyper, "Best HIT #{result[:hit_rate][0]}/#{result[:hit_rate][1].inspect} (#{maxed[:hit_rate]}%)"

    # POINTS
    maxed = get_max(:return, :hit_rate)
    result[:points] = [maxed[:interval], maxed[:range]]
    out :hyper, "Best POINTS #{result[:points][0]}/#{result[:points][1].inspect} (#{maxed[:return]})"

    # STRIKE RATE
    maxed = get_max(:strike_rate, :hit_rate)
    result[:strike_rate] = [maxed[:interval], maxed[:range]]
    out :hyper, "Best STRIKE #{result[:strike_rate][0]}/#{result[:strike_rate][1].inspect} (#{maxed[:strike_rate]}%)"

    result
  end

  def get_max(first_sort, second_sort)
    max_first = @simulations.collect { |s| s[first_sort] }.max
    maxed = @simulations.select { |a| a[first_sort] == max_first }
    max_second = maxed.collect { |s| s[second_sort] }.max

    if maxed.size == 1
      maxed.first
    else
      @simulations.select do |a|
        a[first_sort] == max_first and a[second_sort] == max_second
      end.first
    end
  end
end

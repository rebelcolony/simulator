class HyperSimulation < ActiveRecord::Base
  validates_uniqueness_of :country, scope: [:since, :up_to, :range_min, :range_max, :range_step, :interval_min, :interval_max, :market_type, :rule]

  serialize :results, Hash

  FULL_RANGES = [
    [1, 6], [1, 7], [1, 8], [1, 9], [1, 10], [1, 11], [1, 12], [1, 14], [1, 16], [1, 18], [1, 20],
    [2, 6], [2, 7], [2, 8], [2, 9], [2, 10], [2, 11], [2, 12], [2, 14], [2, 16], [2, 18], [2, 20],
    [3, 6], [3, 7], [3, 8], [3, 9], [3, 10], [3, 11], [3, 12], [3, 14], [3, 16], [3, 18], [3, 20],
    [4, 6], [4, 7], [4, 8], [4, 9], [4, 10], [4, 11], [4, 12], [4, 14], [4, 16], [4, 18], [4, 20],
    [5, 6], [5, 7], [5, 8], [5, 9], [5, 10], [5, 11], [5, 12], [5, 14], [5, 16], [5, 18], [5, 20],
            [6, 7], [6, 8], [6, 9], [6, 10], [6, 11], [6, 12], [6, 14], [6, 16], [6, 18], [6, 20],
                    [7, 8], [7, 9], [7, 10], [7, 11], [7, 12], [7, 14], [7, 16], [7, 18], [7, 20],
                            [8, 9], [8, 10], [8, 11], [8, 12], [8, 14], [8, 16], [8, 18], [8, 20],
                                    [9, 10], [9, 11], [9, 12], [9, 14], [9, 16], [9, 18], [9, 20],
                                             [10, 11],[10, 12], [10, 14], [10, 16], [10, 18], [10, 20],
                                                      [11, 12], [11, 14], [11, 16], [11, 18], [11, 20]
  ]

  def simulate!
    $start = Time.now

    out :hyper, "Preparing for HyperSimulation:"
    out :hyper, "FROM #{since} TO #{up_to}"
    out :hyper, "FULL RANGE #{range_min}..#{range_max} STEP #{range_step}"
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

    # Find the best range and interval for
    res = get_results(FULL_RANGES, 0.5)

    self.results = res
    out :hyper, "SUCCESS - Finished HyperSimulation"

    save
    # max = results.first

    # res = CSV.generate do |csv|
    #   results.each do |result|
    #     max = result if max.first < result.first
    #     csv << result
    #   end
    #   csv << []
    #   csv << max
    # end

    # update result: steps[max[3..-1].index(max.first)]

    # File.open(File.join(Rails.root.to_s.gsub("fast-odds", "selections").gsub("fastodds", "selections").gsub(/releases\/\d{14}/, 'current'), 'public', 'exports', "#{id}.csv"), 'w') { |file| file.write(res) }

  end

  def get_results(ranges, range_step)
    steps = (interval_min..interval_max).step(range_step).map { |a| a.round(2) }.to_a

    i = 0
    simulations = []

    ranges.each do |min_range, max_range|
      out :hyper, "#{(((i += 1) / ranges.size.to_f) * 100).to_i}% - RANGE #{min_range}..#{max_range}"

      steps.map do |interval|
        simulations << DateSimulation.new(
          since: since,
          up_to: up_to,
          interval: interval,
          range_min: min_range,
          range_max: max_range,
          rule: rule,
          races: @races,
          country: country,
          market_type: market_type
        ).simulate!
      end
    end

    result = {}

    # STRIKE RATE
    max_hit_rate = simulations.collect(&:hit_rate).max
    maxed = simulations.select { |a| a.hit_rate == max_hit_rate }
    max_return = maxed.collect(&:return).max

    unless maxed.size == 1
      found = simulations.index(
        simulations
        .select { |a| a.hit_rate == max_hit_rate and a.return == max_return}.first
      )

      maxed = [simulations[found]]
    end

    maxed = maxed.first

    result[:daily_strike_rate] = {interval: maxed.interval, range: maxed.range}

    out :hyper, "For interval #{range_step} STEP: Best STRIKE #{result[:daily_strike_rate][:interval]}/#{result[:daily_strike_rate][:range].inspect} (#{maxed.hit_rate})}"

    # POINTS
    max_return = simulations.collect(&:return).max
    maxed = simulations.select { |a| a.return == max_return }
    max_hit_rate = maxed.collect(&:hit_rate).max

    unless maxed.size == 1
      found = simulations.index(
        simulations
        .select { |a| a.return == max_return and a.hit_rate == max_hit_rate}.first
      )

      maxed = [simulations[found]]
    end

    maxed = maxed.first

    result[:points] = {interval: maxed.interval, range: maxed.range}

    out :hyper, "For interval #{range_step} STEP: Best POINTS #{result[:points][:interval]}/#{result[:points][:range].inspect} (#{maxed.return})"

    # TODO: HIT RATE

    result
  end
end

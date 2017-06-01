class RaceDay < ActiveRecord::Base
  has_many :races
  has_many :markets, through: :races
  has_many :odd_sets, through: :markets

  def self.race_day_hash
    @@rdh ||= connection.select_all("SELECT id, date FROM race_days").inject({}) do |res, val|
      res[val['date']] = val['id']
      res
    end
  end

  def cache_simulations!
    return true if cached

    rules = %w(lay)
    market_types = [1, 3]
    countries = [0, 1, 2, 3]
    intervals = (-0.3..4.5).step(0.01).map { |a| a.round(2) }.to_a
    total_passes = [rules, market_types, countries, intervals].collect(&:size).inject(:*)

    i = 0

    rules.each do |rule|
      market_types.each do |market_type|
        countries.each do |country|
          intervals.each do |interval|
            out :simulations, "PROGRESS: #{(((i += 1) / total_passes) * 100).to_f.round(2)}%"

            HyperSimulation::FULL_RANGES.each do |min_range, max_range|
              Simulation.create(
                race_day_id: id,
                country: country,
                interval: interval,
                market_type: market_type,
                rule: rule,
                range_min: min_range,
                range_max: max_range
              )
            end
          end
        end
      end
    end

    update(cached: true)
  end
end

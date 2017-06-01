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
          out :simulations, "PROGRESS: #{((i / total_passes.to_f) * 100).round}%"

          intervals.each do |interval|
            i += 1

            sql = "SELECT DISTINCT ON (runner_id, market_type) runner_id, value, won, market_type
             FROM odds
             WHERE race_day_id = #{id}
             AND country = #{country}
             AND created_at < (race_start_at - INTERVAL '#{interval} MINUTES')
             ORDER BY runner_id, market_type, created_at DESC;"

            results = Simulation.connection.select_all(sql).inject({}) do |res, row|
              res[row['runner_id']] ||= {}
              res[row['runner_id']][row['market_type']] = [row['value'], row['won']]
              res
            end

            HyperSimulation::FULL_RANGES.each do |range_min, range_max|
              Simulation.new(
                race_day_id: id,
                country: country,
                interval: interval,
                market_type: market_type,
                rule: rule,
                results: results,
                range_min: range_min,
                range_max: range_max
              ).simulate_and_insert!
            end
          end
        end
      end
    end

    update(cached: true)
  end
end

class RaceDay < ActiveRecord::Base
  has_many :races
  has_many :markets, through: :races
  has_many :odd_sets, through: :markets

  has_many :odds
  has_many :simulations

  def self.race_day_hash
    @@rdh ||= connection.select_all("SELECT id, date FROM race_days").inject({}) do |res, val|
      res[val['date']] = val['id']
      res
    end
  end

  def cache_simulations!(force = false)
    out :simulations, "Caching simulations for #{date}"

    update(cached: false) if force

    if cached
      out :simulations, "Simulations already cached for #{date}, bye bye"
      return true
    end

    out :simulations, "Clearing all existing #{simulations.count} simulations for #{date}"

    self.class.connection.execute("DELETE FROM simulations WHERE race_day_id = #{id}")

    market_types_array = [nil, 'WIN', nil, 'PLACE']

    rules = %w(lay)
    out :simulations, "Eligible RULES: #{rules.map(&:upcase).join(', ')}"

    market_types = [1, 3]
    out :simulations, "Eligible MARKETS: #{market_types.collect { |a| market_types_array[a] }.join(', ')}"

    countries = [0, 1, 2, 3]
    out :simulations, "Eligible COUNTRIES: #{countries.collect { |c| Venue::COUNTRY_IDS[c].upcase }.join(', ')}"

    step = 0.1
    intervals = (-0.3..4.5).step(step).map { |a| a.round(2) }.to_a
    out :simulations, "Eligible INTERVALS: #{intervals.first} TO #{intervals.last} STEP #{step}"

    total_passes = [rules, market_types, countries, intervals].collect(&:size).inject(:*)
    out :simulations, "Total Loops: #{total_passes}"

    i = 0

    rules.each do |rule|
      market_types.each do |market_type|
        countries.each do |country|
          out :simulations, "#{((i / total_passes.to_f) * 100).round}% (#{simulations.count} simulations) - #{Venue::COUNTRY_IDS[country].upcase} - #{rule.upcase} - #{market_types_array[market_type]}"

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

    out :simulations, "SUCCESS Created #{simulations.count} simulations for #{date}"

    update(cached: true)
  end

  def import!(force = false)
    out :import, "Importing odds for #{date}"

    update(imported: false) if force

    if imported
      out :import, "Odds already imported for #{date}, bye bye"
      return true
    end

    out :import, "Clearing all existing #{odds.count} odds for #{date}"

    self.class.connection.execute("DELETE FROM odds WHERE race_day_id = #{id}")

    total_passes = markets.count
    out :simulations, "Total Loops: #{total_passes}"

    i = 0

    races.each do |race|
      runners = race.runners.reject(&:removed).collect(&:id)
      out :import, "#{((i / total_passes.to_f) * 100).round}% - #{race.venue.name} #{race.start_at.strftime("%H:%M")}"

      race.markets.each do |market|
        i += 1

        ids = OddSet.connection.select_values("SELECT id FROM odd_sets WHERE market_id = #{market.id}")

        ids.each do |id|
          os = OddSet.find(id)

          os.values.each do |runner_id, val|
            next unless runners.include?(runner_id)
            v = val[:best] || val[2]
            Odd.connection.execute("INSERT INTO odds (runner_id, value, market_type, created_at, race_day_id, race_start_at, won, country) VALUES (#{runner_id},#{v},#{market.market_type_id},'#{os.created_at.to_s(:db)}',#{self.id},'#{race.start_at.to_s(:db)}', '#{market.winners.include?(runner_id) ? 't' : 'f'}','#{race.venue.country_id}');")
          end
        end
      end
    end

    out :import, "SUCCESS Imported #{odds.count} for #{date}"

    update(imported: true)
  end
end

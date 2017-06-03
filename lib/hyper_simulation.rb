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

    base_sql = "
    SELECT interval, range_min, range_max,
    ROUND(SUM(return)::numeric, 2) AS points,
    ROUND((SUM(winners) * 100 / (CASE SUM(total) WHEN 0 THEN 1 ELSE SUM(total) END))::numeric, 2) AS hit_rate,
    ROUND((COUNT(CASE WHEN profit >= 0 THEN 1 END) * 100)::numeric / COUNT(*), 2) AS strike_rate
    FROM simulations
    WHERE race_day_id IN (#{@races.join(', ')}) AND rule = '#{rule}' AND market_type = #{market_type} AND country = #{country}
    GROUP BY interval, range_min, range_max "

    {
      hit_rate: [:hit_rate, :points],
      points: [:points, :hit_rate],
      strike_rate: [:strike_rate, :hit_rate]
    }.each do |meth, sorts|

      result = Simulation.connection.select_all(base_sql + "ORDER BY #{sorts[0]} DESC, #{sorts[1]} DESC LIMIT 1").first.to_h

      self.results[meth] = {
        interval: result['interval'],
        range: result['range_min']..result['range_max'],
        value: result[meth.to_s].to_f
      }

      out :hyper, "Best #{meth.upcase} formula: #{results[meth][:interval]}/#{results[meth][:range].inspect} (#{results[meth][:value]})"
    end

    save
  end
end

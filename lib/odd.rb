class Odd < ActiveRecord::Base
  def self.import(race_day)
    race_day.races.each do |race|
      out :import, "#{race.venue.name} race of #{race.start_at.strftime("%H:%M")}"

      runners = race.runners.reject(&:removed).collect(&:id)

      race.markets.each do |market|
        ids = OddSet.connection.select_values("SELECT id FROM odd_sets WHERE market_id = #{market.id}")

        ids.each do |id|
          os = OddSet.find(id)

          os.values.each do |runner_id, val|
            next unless runners.include?(runner_id)
            v = val[:best] || val[2]
            Odd.connection.execute("INSERT INTO odds (runner_id, value, market_type, created_at, race_day_id, race_start_at, won, country) VALUES (#{runner_id},#{v},#{market.market_type_id},'#{os.created_at.to_s(:db)}',#{race_day.id},'#{race.start_at.to_s(:db)}', '#{market.winners.include?(runner_id) ? 't' : 'f'}','#{race.venue.country_id}');")
          end
        end
      end
    end
  end
end

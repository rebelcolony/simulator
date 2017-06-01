class Simulation < ActiveRecord::Base
  belongs_to :race_day

  validates_uniqueness_of :race_day_id, scope: [:interval, :range_min, :range_max, :market_type, :country, :rule]

  after_create :simulate!

  def simulate!
    selections = []

    sql = "SELECT DISTINCT ON (runner_id, market_type) runner_id, value, won, market_type
     FROM odds
     WHERE race_day_id = #{race_day_id}
     AND country = #{country}
     AND created_at < (race_start_at - INTERVAL '#{interval} MINUTES')
     ORDER BY runner_id, market_type, created_at DESC;"

    Simulation.connection.select_all(sql).inject({}) do |res, row|
      res[row['runner_id']] ||= {}
      res[row['runner_id']][row['market_type']] = [row['value'], row['won']]
      res
    end.each do |runner_id, values|
      b, l, p = values[1].try(:first), values[2].try(:first), values[3].try(:first)
      next unless b and l
      next unless (range_min..range_max).include?(b)
      next if rule == 'lay' and l > b

      sel = {
        runner_id: runner_id,
        won: values[market_type][1],
        best_price: (market_type == 3 ? p : b),
        lay: l,
      }

      sel[:return] = (sel[:won] ? (sel[:best_price] - 1) : -1.0).round(2)
      sel[:profit] = sel[:won] ? sel[:return] * 0.96 : sel[:return]

      selections << sel
    end

    self.total      = selections.count
    self.winners    = selections.select { |a| a[:won] }.count
    self.best_price = selections.collect{ |a| a[:best_price] }.sum.round(2)
    self.return     = selections.collect{ |a| a[:return].to_f }.sum.round(2)
    self.profit     = selections.collect{ |a| a[:profit].to_f }.sum.round(2)

    self.hit_rate = (self.winners.to_f / self.total * 100).round(2)
    self.hit_rate = 0 if self.hit_rate.nan?

    save
  end
end

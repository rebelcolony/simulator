class Simulation < ActiveRecord::Base
  belongs_to :race_day

  attr_accessor :results

  def simulate
    selections = []

    @results.each do |runner_id, values|
      b, l, p = values[1].try(:first), values[2].try(:first), values[3].try(:first)
      next unless b and l
      next if market_type == 3 and p.nil?
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
  end

  def simulate_and_insert!
    simulate
    self.class.connection.execute("INSERT INTO simulations (race_day_id, interval, range_min, range_max, market_type, country, rule, created_at, total, winners, best_price, return, profit, hit_rate) VALUES (#{race_day_id}, #{interval}, #{range_min}, #{range_max}, #{market_type}, #{country}, '#{rule}', '#{Time.now.to_s(:db)}', #{total}, #{winners}, #{best_price}, #{self.return}, #{profit}, #{hit_rate});")
  end
end

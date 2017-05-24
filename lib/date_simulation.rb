class DateSimulation < ActiveRecord::Base

  validates_uniqueness_of :interval, scope: [:since, :up_to, :range_min, :range_max, :market_type, :country, :rule]

  after_create :simulate!

  def simulate!
    simulations = []

    (since..up_to).each do |date|
      simulations << Simulation.where(
        race_day_id: RaceDay.race_day_hash[date.to_s],
        interval: interval,
        range_min: range_min,
        range_max: range_max,
        rule: rule,
        country: country,
        market_type: market_type
      ).first_or_create
    end

    selections = simulations.collect(&:selections).flatten

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

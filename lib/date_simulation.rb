class DateSimulation

  attr_accessor :total, :winners, :best_price, :return, :hit_rate

  def initialize(options = {})
    @since = options[:since]
    @up_to = options[:up_to]
    @interval = options[:interval]
    @range_min = options[:range_min]
    @range_max = options[:range_max]
    @rule = options[:rule]
    @country = options[:country]
    @market_type = options[:market_type]
  end

  def simulate!
    simulations = []

    (@since..@up_to).each do |date|
      simulations << Simulation.where(
        race_day_id: RaceDay.race_day_hash[date.to_s],
        interval: @interval,
        range_min: @range_min,
        range_max: @range_max,
        rule: @rule,
        country: @country,
        market_type: @market_type
      ).first_or_create
    end

    selections = simulations.collect(&:selections).flatten

    @total      = selections.count
    @winners    = selections.select { |a| a[:won] }.count
    @best_price = selections.collect{ |a| a[:best_price] }.sum.round(2)
    @return     = selections.collect{ |a| a[:return].to_f }.sum.round(2)
    @profit     = selections.collect{ |a| a[:profit].to_f }.sum.round(2)

    @hit_rate = (@winners.to_f / @total * 100).round(2)
    @hit_rate = 0 if @hit_rate.nan?

    self
  end
end

class DateSimulation

  attr_accessor :total, :winners, :best_price, :return, :hit_rate

  def initialize(options = {})
    @since = options[:since]
    @up_to = options[:up_to]
    @interval = options[:interval]
    @range_min = options[:range_min]
    @range_max = options[:range_max]
    @rule = options[:rule]
    @races = options[:races]
    @country = options[:country]
    @market_type = options[:market_type]
  end

  def simulate!
    simulations = []

    results = Simulation.connection.select_all("
      SELECT SUM(total) AS total, SUM(winners) AS winners, SUM(best_price) AS best_price, SUM(return) AS return, SUM(profit) AS profit
      FROM simulations
      WHERE race_day_id IN (#{@races.join(', ')})
      AND interval = #{@interval}
      AND range_min = #{@range_min}
      AND range_max = #{@range_max}
      AND rule = '#{@rule}'
      AND country = #{@country}
      AND market_type = #{@market_type}
    ").first

    @total      = results['total']
    @winners    = results['winners']
    @best_price = results['best_price']
    @return     = results['return']
    @profit     = results['profit']

    @hit_rate = (@winners.to_f / @total * 100).round(2)
    @hit_rate = 0 if @hit_rate.nan?

    self
  end
end

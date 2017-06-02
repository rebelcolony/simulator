class DateSimulation

  attr_accessor :total, :winners, :best_price, :return, :hit_rate, :interval, :strike_rate, :range

  def initialize(options = {})
    @since = options[:since]
    @up_to = options[:up_to]
    @interval = options[:interval]
    @range = options[:range]
    @rule = options[:rule]
    @races = options[:races]
    @country = options[:country]
    @metrics = options[:metrics]
    @market_type = options[:market_type]
  end

  def simulate!
    simulations = []

    strike = ", ROUND((COUNT(profit >= 0) * 100)::numeric / COUNT(*), 2) AS strike_rate"

    results = Simulation.connection.select_all("
      SELECT SUM(total) AS total, SUM(winners) AS winners, SUM(best_price) AS best_price, SUM(return) AS return, SUM(profit) AS profit#{strike if @metrics.include?(:strike_rate)}
      FROM simulations
      WHERE race_day_id IN (#{@races.join(', ')})
      AND interval = #{@interval}
      AND range_min = #{@range.min}
      AND range_max = #{@range.max}
      AND rule = '#{@rule}'
      AND country = #{@country}
      AND market_type = #{@market_type}
    ").first

    @total       = results['total']
    @winners     = results['winners']
    @best_price  = results['best_price']
    @return      = results['return']
    @profit      = results['profit']
    @strike_rate = results['strike_rate']

    raise self.inspect unless @total

    @hit_rate = (@winners.to_f / @total * 100).round(2)
    @hit_rate = 0 if @hit_rate.nan?

    self
  end
end

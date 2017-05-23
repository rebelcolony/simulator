class Simulation < ActiveRecord::Base

  belongs_to :race_day

  attr_accessor :selections
  def simulate!
    @selections = []
    runners = {}

    race_day.races
    .where('venues.country': country)
    .where('runners.removed': false)
    .includes(:venue, :runners, :markets).each do |race|

      race.runners.each { |runner| runners[runner.id] = runner }
      time = race.start_at - interval

      back = OddSet.get_odd(race.market(:win).id, time)
      lay = OddSet.get_odd(race.market(:lose).id, time)

      if market_type == 3
        place_market = race.market(:place)
        place = OddSet.get_odd(place_market.id, time)
      end

      next unless back and lay

      back.each do |runner_id, odd|
        runner = runners[runner_id]
        next unless runner
        lay_price = lay[runner_id]

        next if lay_price.blank?

        lay_price = lay_price.values.first
        best = odd[:best] || odd.values.collect(&:to_f).max

        next if rule == 'lay' and lay_price > best
        next unless range.include?(best)

        price = if market_type == 3
          next unless place_market
          next unless place
          next unless place[runner_id]
          place[runner_id][2]
        else
          best
        end

        @selections << runner.selections.new(
          date: race.start_at.to_date,
          market: race.market(MarketType.find(market_type)[:betfair_name].to_sym),
          won: race.market(MarketType.find(market_type)[:betfair_name].to_sym).winners.include?(runner_id),
          best_price: price,
          lay: lay_price
        )
      end
    end

    self.total      = @selections.count
    self.winners    = @selections.select(&:won).count
    self.best_price = @selections.collect(&:best_price).sum.round(2)
    self.return     = @selections.collect(&:return).collect(&:to_f).sum.round(2)
    self.profit     = @selections.collect(&:profit).collect(&:to_f).sum.round(2)

    self.hit_rate = (self.winners.to_f / self.total * 100).round(2)
    self.hit_rate = 0 if self.hit_rate.nan?

    save
  end

  def range
    range_min..range_max
  end
end

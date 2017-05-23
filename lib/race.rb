class Race < ActiveRecord::Base
  belongs_to :venue
  belongs_to :race_day

  has_many :markets
  has_many :runners

  def market(type = :win)
    unless @markets
      @markets = {}

      markets.each do |market|
        @markets[MarketType.find(market.market_type_id)[:betfair_name].to_sym] = market
      end
    end

    @markets[type]
  end
end

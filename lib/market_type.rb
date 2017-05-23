class MarketType
  MARKET_TYPES = [
    {id: 1, name: 'Win And Each Way', betfair_name: 'win',   internal: 'BACK'},
    {id: 2, name: 'Not To Win',       betfair_name: 'lose',  internal: 'LAY'},
    {id: 3, name: 'To Be Placed',     betfair_name: 'place', internal: 'PLACE'}
  ]

  def self.type(type)
    MARKET_TYPES.find{ |a| a[:betfair_name] == type.to_s}
  end

  def self.find(id)
    MARKET_TYPES.find{ |a| a[:id] == id}
  end
end

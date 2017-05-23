class OddSet < ActiveRecord::Base
  belongs_to :market
  serialize :values, Hash

  def self.get_odd(market_id, time)
    res = connection.select_value(
      "SELECT values FROM odd_sets WHERE market_id = #{market_id} AND (created_at <= '#{time.to_s(:db)}')"
    )
    res ? YAML.load(res) : nil
  end
end

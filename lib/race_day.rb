class RaceDay < ActiveRecord::Base
  has_many :races
  has_many :markets, through: :races
  has_many :odd_sets, through: :markets

  def self.race_day_hash
    @@rdh ||= connection.select_all("SELECT id, date FROM race_days").inject({}) do |res, val|
      res[val['date']] = val['id']
      res
    end
  end
end

class Venue < ActiveRecord::Base
  has_many :races

  COUNTRY_IDS = ['ie', 'za', 'us', 'gb']

  def country_id
    COUNTRY_IDS.index(country)
  end
end

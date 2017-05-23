class RaceDay < ActiveRecord::Base
  has_many :races
  has_many :markets, through: :races
  has_many :odd_sets, through: :markets


end

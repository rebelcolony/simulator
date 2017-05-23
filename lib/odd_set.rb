class OddSet < ActiveRecord::Base
  belongs_to :market
  serialize :values, Hash
end

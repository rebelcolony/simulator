class Runner < ActiveRecord::Base
  belongs_to :race
  has_many :selections
end

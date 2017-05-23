class Market < ActiveRecord::Base
  belongs_to :race
  has_many :odd_sets, dependent: :destroy
  has_many :selections, dependent: :destroy
end

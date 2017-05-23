class Selection < ActiveRecord::Base
  belongs_to :runner
  belongs_to :market

  attr_accessor :lay

  after_initialize :calculations

  def calculations
    self.return = (won ? (best_price / 100.0 - 1) : -1.0).round(2)
    self.profit = won ? self.return * 0.96 : self.return
  end
end

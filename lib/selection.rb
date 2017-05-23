class Selection < ActiveRecord::Base
  belongs_to :runner
  belongs_to :market

  attr_accessor :lay
end

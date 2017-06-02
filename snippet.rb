

a= Simulation.where(
race_day_id: RaceDay.find_by_date('2016-06-28').id,
interval: 0.55,
range_min: 1.7,
range_max: 3.3,
market_type: 3,
country: 3,
rule: 'lay'
).first_or_create

a = HyperSimulation.create(country: 3, up_to: Date.new(2016, 6, 12), market_type: 3, range_step: 0.01)

def ti(val = '#')
  puts val*50
  puts "######## ELAPSED: #{((Time.now - $start) * 1000).round(5)}ms"
  puts val*50
end

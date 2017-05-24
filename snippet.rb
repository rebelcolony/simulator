

a= Simulation.where(
race_day_id: RaceDay.find_by_date('2016-06-28').id,
interval: 0.55,
range_min: 1.7,
range_max: 3.3,
market_type: 3,
country: 'gb',
rule: 'lay'
).first_or_create

def ti(val = '#')
  puts val*50
  puts "######## ELAPSED: #{((Time.now - $start) * 1000).round(5)}ms"
  puts val*50
end

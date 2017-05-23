# encoding: utf-8
namespace :import do
  desc "Import all odd_sets to odds"
  task :all => :environment do
    Odd.delete_all

    RaceDay.order(:date).all.each do |race_day|
      puts "Importing #{race_day.date}..."
      Odd.import(race_day)
    end
  end
end


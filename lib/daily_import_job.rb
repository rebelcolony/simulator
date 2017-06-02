class DailyImportJob < ActiveJob::Base
  def perform
    RaceDay.create_import_jobs!
    DailyImportJob.set(wait_until: (Date.tomorrow.in_time_zone('London').change(hour: 7))).perform_later
  end
end

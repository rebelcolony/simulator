class HyperSimulation < ActiveRecord::Base
  validates_uniqueness_of :country, scope: [:since, :up_to, :range_min, :range_max, :range_step, :interval_min, :interval_max, :market_type, :rule, :metrics]

  serialize :results, Hash

  def simulate!
    $start = Time.now

    steps = (interval_min..interval_max).step(range_step).map { |a| a.round(2) }.to_a

    i = 0

    ranges = if false#options['full'] == '1'
      [
        [1, 6], [1, 7], [1, 8], [1, 9], [1, 10], [1, 11], [1, 12], [1, 14], [1, 16], [1, 18], [1, 20],
        [2, 6], [2, 7], [2, 8], [2, 9], [2, 10], [2, 11], [2, 12], [2, 14], [2, 16], [2, 18], [2, 20],
        [3, 6], [3, 7], [3, 8], [3, 9], [3, 10], [3, 11], [3, 12], [3, 14], [3, 16], [3, 18], [3, 20],
        [4, 6], [4, 7], [4, 8], [4, 9], [4, 10], [4, 11], [4, 12], [4, 14], [4, 16], [4, 18], [4, 20],
        [5, 6], [5, 7], [5, 8], [5, 9], [5, 10], [5, 11], [5, 12], [5, 14], [5, 16], [5, 18], [5, 20],
                [6, 7], [6, 8], [6, 9], [6, 10], [6, 11], [6, 12], [6, 14], [6, 16], [6, 18], [6, 20],
                        [7, 8], [7, 9], [7, 10], [7, 11], [7, 12], [7, 14], [7, 16], [7, 18], [7, 20],
                                [8, 9], [8, 10], [8, 11], [8, 12], [8, 14], [8, 16], [8, 18], [8, 20],
                                        [9, 10], [9, 11], [9, 12], [9, 14], [9, 16], [9, 18], [9, 20],
                                                 [10, 11],[10, 12], [10, 14], [10, 16], [10, 18], [10, 20],
                                                          [11, 12], [11, 14], [11, 16], [11, 18], [11, 20]
      ]
    elsif false#options['mini'] == '1'
      [
        [1.6, 2.2], [1.6, 2.4], [1.6, 2.6], [1.6, 2.8], [1.6, 3.0], [1.6, 3.2], [1.6, 3.4],
        [1.6, 3.6], [1.6, 3.8], [1.6, 4.0], [1.6, 4.2], [1.6, 4.4], [1.6, 4.6], [1.6, 5.0],

        [1.8, 2.2], [1.8, 2.4], [1.8, 2.6], [1.8, 2.8], [1.8, 3.0], [1.8, 3.2], [1.8, 3.4],
        [1.8, 3.6], [1.8, 3.8], [1.8, 4.0], [1.8, 4.2], [1.8, 4.4], [1.8, 4.6], [1.8, 5.0],

        [2.0, 2.2], [2.0, 2.4], [2.0, 2.6], [2.0, 2.8], [2.0, 3.0], [2.0, 3.2], [2.0, 3.4],
        [2.0, 3.6], [2.0, 3.8], [2.0, 4.0], [2.0, 4.2], [2.0, 4.4], [2.0, 4.6], [2.0, 5.0],

        [2.2, 2.4], [2.2, 2.6], [2.2, 2.8], [2.2, 3.0], [2.2, 3.2], [2.2, 3.4], [2.2, 3.6],
        [2.2, 3.8], [2.2, 4.0], [2.2, 4.2], [2.2, 4.4], [2.2, 4.6], [2.2, 4.8], [2.2, 5.0],

        [2.4, 2.6], [2.4, 2.8], [2.4, 3.0], [2.4, 3.2], [2.4, 3.4], [2.4, 3.6], [2.4, 3.8],
        [2.4, 4.0], [2.4, 4.2], [2.4, 4.4], [2.4, 4.6], [2.4, 4.8], [2.4, 5.0],

        [2.6, 2.8], [2.6, 3.0], [2.6, 3.2], [2.6, 3.4], [2.6, 3.6], [2.6, 3.8], [2.6, 4.0],
        [2.6, 4.2], [2.6, 4.4], [2.6, 4.6], [2.6, 4.8], [2.6, 5.0],

        [2.8, 3.0], [2.8, 3.2], [2.8, 3.4], [2.8, 3.6], [2.8, 3.8], [2.8, 4.0], [2.8, 4.2],
        [2.8, 4.4], [2.8, 4.6], [2.8, 4.8], [2.8, 5.0],

        [3.0, 3.2], [3.0, 3.4], [3.0, 3.6], [3.0, 3.8], [3.0, 4.0], [3.0, 4.2], [3.0, 4.4],
        [3.0, 4.6], [3.0, 4.8], [3.0, 5.0],

        [3.2, 3.4], [3.2, 3.6], [3.2, 3.8], [3.2, 4.0], [3.2, 4.2], [3.2, 4.4],
        [3.2, 4.6], [3.2, 4.8], [3.2, 5.0],

        [3.4, 3.6], [3.4, 3.8], [3.4, 4.0], [3.4, 4.2], [3.4, 4.4], [3.4, 4.6], [3.4, 4.8], [3.4, 5.0],

        [3.6, 3.8], [3.6, 4.0], [3.6, 4.2], [3.6, 4.4], [3.6, 4.6], [3.6, 4.8], [3.6, 5.0],

        [3.8, 4.0], [3.8, 4.2], [3.8, 4.4], [3.8, 4.6], [3.8, 4.8], [3.8, 5.0],

        [4.0, 4.2], [4.0, 4.4], [4.0, 4.6], [4.0, 4.8], [4.0, 5.0],

        [4.2, 4.4], [4.2, 4.6], [4.2, 4.8], [4.2, 5.0],

        [4.4, 4.6], [4.4, 4.8], [4.4, 5.0],

        [4.6, 4.8], [4.6, 5.0],

        [4.8, 5.0]
      ]
    else
      [[range_min, range_max], [range_min+1, range_max+1]]
    end

    ranges.each do |min_range, max_range|
      steps_results = steps.map do |interval|
        simulation = DateSimulation.where(
          since: since,
          up_to: up_to,
          interval: interval,
          range_min: min_range,
          range_max: max_range,
          rule: rule,
          country: country,
          market_type: market_type
        ).first_or_create

        out :hyper, "PROGRESS: #{(((i += 1) / (steps.size.to_f * ranges.size)) * 100).to_i}%"
        simulation
      end

      result = {}

      if metrics.include?('daily_strike_rate')
        max = steps_results.collect(&:hit_rate).max
        maxed = steps_results.select { |a| a.hit_rate == max}

        unless maxed.size == 1
          max_return = maxed.collect(&:return).max

          found = steps_results.index(steps_results
            .select { |a| a.hit_rate == max}
            .select { |a| a.return == max_return}.first)

          steps_results[found].hit_rate += 1
        end

        result[:daily_strike_rate] = steps_results.collect(&:hit_rate)
      end

      if metrics.include?('points')
        result[:points] = steps_results.collect(&:return)
      end

      if metrics.include?('hit_rate')
        result[:hit_rate] = steps_results.collect(&:hit_rate)
      end

      self.results[[min_range, max_range]] = result
    end

    save
    # raise results.inspect
    # max = results.first

    # res = CSV.generate do |csv|
    #   results.each do |result|
    #     max = result if max.first < result.first
    #     csv << result
    #   end
    #   csv << []
    #   csv << max
    # end

    # update result: steps[max[3..-1].index(max.first)]

    # File.open(File.join(Rails.root.to_s.gsub("fast-odds", "selections").gsub("fastodds", "selections").gsub(/releases\/\d{14}/, 'current'), 'public', 'exports', "#{id}.csv"), 'w') { |file| file.write(res) }

  end
end

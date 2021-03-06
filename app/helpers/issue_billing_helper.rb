module IssueBillingHelper

  def billing_to_csv(issues, total_hours)
    export = FCSV.generate(:col_sep => ',') do |csv|
      # add headers
      csv << ["Id", "Subject", "Created date and time", "Raised by", "Actioned by", "Time spent (hours)"]

      # add data
      issues.each do |i|
        csv << [i.id, i.subject, format_time(i.created_on), i.raised_by, (i.assigned_to.nil?) ? i.author : i.assigned_to, get_billable_hours(i.hours).to_s]
      end

      # add total at bottom
      csv << [nil, nil, nil, nil,"Total", total_hours]
    end
    export
  end

  def get_billable_hours(hours)
    # make sure to return 0 if there are no hours
    return 0 if hours == 0

    # if the amount of time is less than 0.5 (half hour) bill 0.5
    return 0.5 if hours <= 0.5

    # if the amount is a 15 minute increment (0.25) then leave un touched
    return hours if hours % 0.25 == 0.0

    # finally push the hours up to the nearest 15 minutes (0.25)
    return (hours * 4).ceil.to_f / 4
  end

end
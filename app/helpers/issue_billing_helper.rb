module IssueBillingHelper

  def billing_to_csv(issues)
    export = FCSV.generate(:col_sep => ',') do |csv|
      # add headers
      csv << %w(Id Subject Date Actioned Time)

      # add data
      issues.each do |i|
        csv << [i.id, i.subject, format_time(i.created_on), (i.assigned_to.nil?) ? i.author : i.assigned_to, i.hours.to_s]
      end

    end
    export
  end

end
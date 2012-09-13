class SupportReport < Prawn::Document
  include IssueBillingHelper
  include Redmine::I18n

  def to_pdf(issues, project, total_hours, start_date, end_date)
    font_size(16) { text "Support Log" }
    
    move_down 10
    
    font( "Helvetica", :style => :bold ) { text "Customer:" }
    text project.name
    
    move_down 10
    
    font( "Helvetica", :style => :bold ) { text "Period:" }
    text "#{start_date} - #{end_date}"

    move_down 20
    font_size 10

    issues_array = create_issues_table(issues)

    Support.log_debug(issues_array)

    table(issues_array)

    render
  end

  private
  def create_issues_table(issues)
    table = []

    # add the heading
    table << ["Id", "Subject", "Date", "Raised by", "Actioned by", "Time spent (hours)"]

    issues.each do |i|
      table << [i.id.to_s, i.subject, format_time(i.created_on), i.custom_value.split(";").first.strip, (i.assigned_to.nil?) ? i.author.to_s : i.assigned_to.to_s, get_billable_hours(i.hours).to_s]
    end

    table
  end
end
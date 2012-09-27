class SupportReport < Prawn::Document
  include IssueBillingHelper
  include Redmine::I18n

  def initialize
    super(:page_size => "A4", :page_layout => :landscape)
  end

  def to_pdf(issues, project, total_hours, start_date, end_date)

    image "#{IssueBilling::LOGO_URL}#{Setting.plugin_issue_billing['ib_logo_image']}", \
          :height => 50, :vposition => :top, :position => :right

    font_size(16) { text "Support Log" }

    font_size 10

    move_down 10

    text "<b>Customer:</b> #{project.name}", :inline_format => true

    move_down 10

    text "<b>Period:</b> #{start_date} to #{end_date} (inclusive)", :inline_format => true

    move_down 10

    text "<b>Total hours:</b> #{total_hours}", :inline_format => true

    move_down 20

    issues_array = create_issues_table(issues, total_hours)

    font_size 8
    table(issues_array, :header => true, :cell_style => { :border_width => 0, :inline_format => true })

    page_string = "page <page> of <total>"

    # number_pages page_string, {
    #   :align => :right,
    #   :width => 50,
    #   :at => [bounds.right - 70, bounds.bottom + 8],
    #   :overflow => :expand
    # }

    render
  end

  private
    def create_issues_table(issues, total_hours)
      table = []

      # add the heading
      table << ["<b>Id</b>", "<b>Subject</b>", "<b>Created date and time</b>", "<b>Raised by</b>", "<b>Actioned by</b>", "<b>Time spent (hours)</b>"]

      issues.each do |i|
        table << [i.id.to_s, i.subject, format_time(i.created_on), i.raised_by, (i.assigned_to.nil?) ? i.author.to_s : i.assigned_to.to_s, i.hours.to_s]
      end

      # Add footer with total hours
      table << ["", "", "", "", "", "<b>#{total_hours.to_s}</b>"]

      table
    end
end
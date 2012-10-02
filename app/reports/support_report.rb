class SupportReport < Prawn::Document
  include IssueBillingHelper
  include Redmine::I18n

  def initialize
    super(:page_size => "A4", :page_layout => :landscape)
  end

  def to_pdf(issues, project, total_hours, start_date, end_date)

    logo_height = Setting.plugin_issue_billing['ib_logo_height'].to_i || 30
    logo = Setting.plugin_issue_billing['ib_logo_image'] || 'logo.png'

    image "#{IssueBilling::LOGO_URL}#{logo}", { :height => logo_height, :vposition => :top, :position => :right }

    font_size(10) { text "<b>Support Log</b>", :inline_format => true }

    font_size 8

    move_down 4

    text "<b>Customer:</b> #{project.name}", :inline_format => true

    move_down 4

    text "<b>Period:</b> #{start_date} to #{end_date} (inclusive)", :inline_format => true

    move_down 4

    text "<b>Total hours:</b> #{total_hours}", :inline_format => true

    move_down 7

    issues_array = create_issues_table(issues, total_hours)

    font_size 6
    table(issues_array, :header => true, :width => (bounds.right - 1), :cell_style => { :border_width => 0, :inline_format => true }) do
      row(0).background_color = "CCCCCC"
      cells.padding = 2
    end

    page_string = "page <page> of <total>"

    number_pages page_string, {
      :align => :right,
      :width => 50,
      :at => [bounds.right - 70, -2]
    }

    render
  end

  private
    def create_issues_table(issues, total_hours)
      table = []

      # add the heading
      table << ["<b>ID</b>", "<b>Subject</b>", "<b>Created date and time</b>", "<b>Raised by</b>", "<b>Actioned by</b>", "<b>Time spent (hours)</b>"]

      issues.each do |i|
        table << [i.id.to_s, i.subject, format_time(i.created_on), i.raised_by, (i.assigned_to.nil?) ? i.author.to_s : i.assigned_to.to_s, i.hours.to_s]
      end

      # Add footer with total hours
      table << ["", "", "", "", "", "<b>#{total_hours.to_s}</b>"]

      table
    end
end
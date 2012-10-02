require "#{File.expand_path(File.dirname(__FILE__)+ '/../')}/reports/support_report.rb"

class IssueBillingController < ApplicationController
  include IssueBillingHelper

  unloadable

  before_filter :find_project, :authorize

  # list all billable issues for a project
  def issues
    issues_scope = Issue \
    .joins(:status) \
    .joins(:time_entries) \
    .includes(:time_entries) \
    .includes(:custom_values) \
    .where(:project_id => @project.id) \
    .scoped

    @billing_filter = BillingFilter.new(params[:billing_filter])

    if @billing_filter.valid?
      # create the time range object
      time_range = @billing_filter.start_date..@billing_filter.end_date
      issues_scope = issues_scope.where(:time_entries => { :spent_on => time_range }).scoped

      if @billing_filter.closed
        issues_scope = issues_scope.where(:issue_statuses => { :is_closed => true }).scoped
      end
    end

    # get only the set trackers
    if is_setting_set?('ib_tracker_id')
      issues_scope = issues_scope.where(:tracker_id => Setting.plugin_issue_billing['ib_tracker_id']).scoped
    end

    @activities = (is_setting_set?('ib_non_billable_activity_ids')) ? [] : Setting.plugin_issue_billing['ib_non_billable_activity_ids'].to_s.split(";")

    @issues = build_issues_list(issues_scope.all)

    # add total hours
    @total_hours = @issues.inject(0) { |sum, item| sum + item.hours }

    respond_to do |format|
      format.html { render :template => 'issue_billing/issues' }
      format.csv  { send_data(billing_to_csv(@issues, @total_hours), :type => 'text/csv; header=present', :filename => "#{@project.name}_report.csv") }
      format.pdf  { send_data(SupportReport.new.to_pdf(@issues, @project, @total_hours, @billing_filter.start_date, @billing_filter.end_date), :type => 'application/pdf', :filename => "#{@project.name}_report.pdf") }
    end
  end

  private
    def find_project
      # @project variable must be set before calling the authorize filter
      @project = Project.find(params[:id])
    end

    def is_setting_set?(setting_name)
      return false if Setting.plugin_issue_billing[setting_name].to_s == '0' || Setting.plugin_issue_billing[setting_name].blank?
      true
    end

    def build_issues_list(issues)
      # remove issues marked as non-billable
      issues.delete_if { |i| !i.custom_value_for(Setting.plugin_issue_billing['ib_non_billable_custom_id'].to_i).nil? \
        && i.custom_value_for(Setting.plugin_issue_billing['ib_non_billable_custom_id'].to_i).value == "1" }

      issues.map! do |i|
        # dynamically give it an hours property and raised by
        i.class.module_eval do
          attr_accessor :hours
          attr_accessor :raised_by
        end

        # sum all the hours
        i.hours = i.time_entries.inject(0) do |sum, t|
          if @activities.include? t.id.to_s
            sum
          else
            sum + t.hours
          end
        end

        # convert to billable hours
        i.hours = get_billable_hours(i.hours)

        # set the raised by
        if is_setting_set?('ib_raised_by_id')
          begin
            i.raised_by = i.custom_value_for(Setting.plugin_issue_billing['ib_raised_by_id']).value.split(";").first.strip
          rescue NoMethodError
            i.raised_by = i.author.to_s
          end
        else
          i.raised_by = i.author.to_s
        end
        i
      end
    end

end

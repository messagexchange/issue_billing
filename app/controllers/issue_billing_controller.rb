require "#{File.expand_path(File.dirname(__FILE__)+ '/../')}/reports/support_report.rb"

class IssueBillingController < ApplicationController
  include IssueBillingHelper

  unloadable

  before_filter :find_project, :authorize

  # list all billable issues for a project
  def issues
    issues_scope = Issue \
                   .joins(:time_entries) \
                   .joins(:status) \
                   .where(:custom_values => { :customized_type => 'Issue' }) \
                   .where(:project_id => @project.id) \
                   .where(:issue_statuses => { :is_closed => true }) \
                   .includes("time_entries") \
                   .select("issues.id as id, issues.subject as subject, #{CustomValue.table_name}.value as custom_value,issues.assigned_to_id as assigned_to_id,issues.created_on as created_on, sum(time_entries.hours) as hours") \
                   .group("issues.id").scoped

    @billing_filter = BillingFilter.new(params[:billing_filter])

    if @billing_filter.valid?
      issues_scope = issues_scope.where("issues.updated_on > ?", @billing_filter.start_date) unless @billing_filter.start_date.nil?
      issues_scope = issues_scope.where("issues.updated_on <= ?", @billing_filter.end_date) unless @billing_filter.end_date.nil?
    end

    unless Setting.plugin_issue_billing['ib_raised_by_id'] == '0' && Setting.plugin_issue_billing['ib_raised_by_id'].nil?
      issues_scope = issues_scope.joins("LEFT OUTER JOIN #{CustomValue.table_name} ON #{CustomValue.table_name}.customized_id = #{Issue.table_name}.id") \
                                 .where(:custom_values => { :customized_type => 'Issue' }) \
                                 .where(:custom_values => { :custom_field_id => Setting.plugin_issue_billing['ib_raised_by_id'] }) \
                                 .select("#{CustomValue.table_name}.value as custom_value")
    end

    # get only the set trackers
    unless Setting.plugin_issue_billing['ib_tracker_id'] == '0'
      issues_scope = issues_scope.where(:tracker_id =>  Setting.plugin_issue_billing['ib_tracker_id'])
    end

    unless Setting.plugin_issue_billing['ib_non_billable_activity_ids'] == '0'
      activities = Setting.plugin_issue_billing['ib_non_billable_activity_ids'].split(";")
      issues_scope = issues_scope.where("#{TimeEntry.table_name}.activity_id NOT IN (?)", activities)
    end

    @issues = issues_scope.all

    # add total hours
    @total_hours = @issues.inject(0) { |sum, item| sum + get_billable_hours(item.hours) }

    respond_to do |format|
      format.html { render :template => 'issue_billing/issues' }
      format.csv  { send_data(billing_to_csv(@issues, @total_hours), :type => 'text/csv; header=present', :filename => 'export.csv') }
      format.pdf  { send_data(SupportReport.new.to_pdf(@issues, @project, @total_hours, @billing_filter.start_date, @billing_filter.end_date), :type => 'application/pdf', :filename => 'export.pdf') }
    end
  end

  private
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id])
  end

end

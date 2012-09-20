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
    .where(:project_id => @project.id) \
    .where(:issue_statuses => { :is_closed => true }) \
    .select("issues.id as id, issues.subject as subject, issues.assigned_to_id as assigned_to_id, \
      issues.author_id as author_id, issues.created_on as created_on, sum(time_entries.hours) as hours") \
    .group("issues.id") \
    .scoped

    @billing_filter = BillingFilter.new(params[:billing_filter])

    if @billing_filter.valid?
      issues_scope = issues_scope.where("issues.created_on >= ?", @billing_filter.start_date).scoped unless @billing_filter.start_date.nil?
      issues_scope = issues_scope.where("issues.created_on <= ?", @billing_filter.end_date).scoped unless @billing_filter.end_date.nil?
    end

    unless Setting.plugin_issue_billing['ib_raised_by_id'].to_s == '0'
      issues_scope = issues_scope.joins("LEFT OUTER JOIN #{CustomValue.table_name} ON #{CustomValue.table_name}.customized_id = #{Issue.table_name}.id") \
      .where(:custom_values => { :customized_type => 'Issue' }) \
      .where(:custom_values => { :custom_field_id => Setting.plugin_issue_billing['ib_raised_by_id'] }) \
      .select("#{CustomValue.table_name}.value as custom_value").scoped
    end

    # get only the set trackers
    unless Setting.plugin_issue_billing['ib_tracker_id'].to_s == '0'
      issues_scope = issues_scope.where(:tracker_id => Setting.plugin_issue_billing['ib_tracker_id']).scoped
    end

    unless Setting.plugin_issue_billing['ib_non_billable_activity_ids'].to_s == '0'
      activities = Setting.plugin_issue_billing['ib_non_billable_activity_ids'].to_s.split(";")
      issues_scope = issues_scope.where("#{TimeEntry.table_name}.activity_id NOT IN (?)", activities).scoped
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

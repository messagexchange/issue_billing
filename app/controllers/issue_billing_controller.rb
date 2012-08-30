class IssueBillingController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  # list all billable issues for a project
  def issues
    issues_scope = Issue.joins(:time_entries) \
                   .joins(:status) \
                   .where(:project_id => @project.id) \
                   .where("issue_statuses.is_closed = ?", true) \
                   .includes("time_entries") \
                   .select("issues.id as id, issues.subject as subject, issues.created_on as created_on, sum(time_entries.hours) as hours") \
                   .group("issues.id").scoped

    @billing_filter = BillingFilter.new(params[:billing_filter])

    if @billing_filter.valid?
      issues_scope = issues_scope.where("issues.updated_on > ?", @billing_filter.start_date) unless @billing_filter.start_date.nil?
      issues_scope = issues_scope.where("issues.updated_on <= ?", @billing_filter.end_date) unless @billing_filter.end_date.nil?
    end

    @issues = issues_scope
  end

  private
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id])
  end

end

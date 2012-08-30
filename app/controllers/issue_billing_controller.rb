class IssueBillingController < ApplicationController
  unloadable

  # list all projects and their billed time
  def index
    @projects = TimeEntry.includes("project") \
                         .joins(:issue) \
                         .select("time_entires.project_id, sum(hours) as hours") \
                         .group("time_entries.project_id")
  end

  # list all billable issues for a project
  def issues
    id = params[:id]
    @billing_project = Project.find(id)
    issues_scope = Issue.joins(:time_entries) \
                   .where(:project_id => id) \
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

end

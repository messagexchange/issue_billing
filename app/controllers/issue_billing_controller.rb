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
    @billing_filter = BillingFilter.new
    @billing_project = Project.find(id)
    @issues = Issue.joins(:time_entries) \
                   .where(:project_id => id) \
                   .includes("time_entries") \
                   .select("issues.id as id, issues.subject as subject, issues.created_on as created_on, sum(time_entries.hours) as hours") \
                   .group("issues.id")
  end

end

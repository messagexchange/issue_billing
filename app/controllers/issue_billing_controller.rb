class IssueBillingController < ApplicationController
  include IssueBillingHelper
  include Redmine::Export::PDF

  unloadable

  before_filter :find_project, :authorize

  # list all billable issues for a project
  def issues
    issues_scope = Issue.joins(:time_entries) \
                   .joins(:status) \
                   .joins(:assigned_to) \
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

    # setup pagination
    # @limit = per_page_option
    # @issue_count = issues_scope.count
    # @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
    # @offset ||= @issue_pages.current.offset

    @issues = issues_scope #.offset(@offset).limit(@limit)

    respond_to do |format|
      format.html { render :template => 'issue_billing/issues' }
      format.csv  { send_data(billing_to_csv(@issues), :type => 'text/csv; header=present', :filename => 'export.csv') }
      format.pdf  { send_data(issues_to_pdf(@issues, @project, nil), :type => 'application/pdf', :filename => 'export.pdf') }
    end
  end

  private
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id])
  end

end

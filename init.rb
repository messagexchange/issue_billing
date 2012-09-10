Redmine::Plugin.register :issue_billing do
  name 'Issue Billing plugin'
  author 'Paul Van de Vreede'
  description 'Create billing report from issue time entries.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # add billing permission
  permission :view_billing, :issue_billing => :issues

  # add billing menu option
  menu(
    :project_menu, 
    :billing, 
    { :controller => 'issue_billing', :action => 'issues' }, 
    :caption => 'Billing', 
    :before => :settings
  )

  # settings for billing
  settings :partial => 'issue_billing_settings', :default => {
    'ib_tracker_id' => 0,
    'ib_non_billable_activity_ids' => 0,
    'ib_raised_by_id' => 0
  }
end



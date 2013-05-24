require 'prawn'

Redmine::Plugin.register :issue_billing do
  name 'Issue Billing plugin'
  author 'Paul Van de Vreede'
  description 'Create billing report from issue time entries.'
  version '0.8.1'
  url 'https://github.com/messagexchange/issue_billing'
  author_url 'https://github.com/messagexchange'

  # add billing permission
  permission :view_billing, :issue_billing => :issues

  # add billing menu option
  menu(
    :project_menu,
    :issue_billing,
    { :controller => 'issue_billing', :action => 'issues' },
    :caption => 'Billing',
    :before => :settings
  )

  # settings for billing
  settings :partial => 'issue_billing_settings', :default => {
    'ib_tracker_id' => 0,
    'ib_non_billable_activity_ids' => 0,
    'ib_raised_by_id' => 0,
    'ib_logo_image' => File.join(File.expand_path('../', __FILE__), 'logos', 'logo.png'),
    'ib_non_billable_custom_id' => 0,
    'ib_logo_height' => 30
  }
end


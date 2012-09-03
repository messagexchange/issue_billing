# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match "/billing/:id(.:format)" => "issue_billing#issues", :as => :billing_issues
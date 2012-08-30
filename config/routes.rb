# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match "/billing/:id" => "issue_billing#issues", :as => :billing_issues
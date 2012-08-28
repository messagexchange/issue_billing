# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match "/billing" => "issue_billing#index"
match "/billing/:id" => "issue_billing#issues"
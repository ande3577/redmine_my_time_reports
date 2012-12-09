# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'my_time_entries' => 'timelog#my_details'
match '/my_time_entries/my_report' => 'timelog#my_report'
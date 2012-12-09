require_dependency 'redmine_my_time_reports_timelog_controller_patch'
require_dependency 'my_time_report'

Rails.configuration.to_prepare do
    unless TimelogController.included_modules.include?(RedmineMyTimeReportsTimelogControllerPatch)
      TimelogController.send(:include, RedmineMyTimeReportsTimelogControllerPatch)
    end
end

Redmine::Plugin.register :redmine_my_time_reports do
  
  name 'Redmine My Time Reports'
  author 'David Anderson'
  description 'This is a plugin that allows for viewing only the user\'s time reports.'
  version '0.0.1'
  url 'https://www.github.com/ande3577/redmine_my_time_reports'
  author_url 'https://www.github.com/ande3577'
end

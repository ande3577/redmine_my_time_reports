module Redmine
  module Helpers
    class MyTimeReport < Redmine::Helpers::TimeReport
      def initialize(project, issue, criteria, columns, from, to, user)
         @project = project
         @issue = issue
    
         @criteria = criteria || []
         @criteria = @criteria.select{|criteria| available_criteria.has_key? criteria}
         @criteria.uniq!
         @criteria = @criteria[0,3]
    
         @columns = (columns && %w(year month week day).include?(columns)) ? columns : 'month'
         @from = from
         @to = to
         
         @user = user
         
         run
       end
       
       def available_criteria
         @available_criteria || load_available_criteria
       end
        
      private
       
        def run
          unless @criteria.empty?
            scope = TimeEntry.visible.spent_between(@from, @to).where(:user_id => @user.id)
            if @issue
              scope = scope.on_issue(@issue)
            elsif @project
              scope = scope.on_project(@project, Setting.display_subprojects_issues?)
            end
            time_columns = %w(tyear tmonth tweek spent_on)
            @hours = []
            scope.sum(:hours, :include => :issue, :group => @criteria.collect{|criteria| @available_criteria[criteria][:sql]} + time_columns).each do |hash, hours|
              h = {'hours' => hours}
              (@criteria + time_columns).each_with_index do |name, i|
                h[name] = hash[i]
              end
              @hours << h
            end
            
            @hours.each do |row|
              case @columns
              when 'year'
                row['year'] = row['tyear']
              when 'month'
                row['month'] = "#{row['tyear']}-#{row['tmonth']}"
              when 'week'
                row['week'] = "#{row['tyear']}-#{row['tweek']}"
              when 'day'
                row['day'] = "#{row['spent_on']}"
              end
            end
            
            if @from.nil?
              min = @hours.collect {|row| row['spent_on']}.min
              @from = min ? min.to_date : Date.today
            end
        
            if @to.nil?
              max = @hours.collect {|row| row['spent_on']}.max
              @to = max ? max.to_date : Date.today
            end
            
            @total_hours = @hours.inject(0) {|s,k| s = s + k['hours'].to_f}
        
            @periods = []
            # Date#at_beginning_of_ not supported in Rails 1.2.x
            date_from = @from.to_time
            # 100 columns max
            while date_from <= @to.to_time && @periods.length < 100
              case @columns
              when 'year'
                @periods << "#{date_from.year}"
                date_from = (date_from + 1.year).at_beginning_of_year
              when 'month'
                @periods << "#{date_from.year}-#{date_from.month}"
                date_from = (date_from + 1.month).at_beginning_of_month
              when 'week'
                @periods << "#{date_from.year}-#{date_from.to_date.cweek}"
                date_from = (date_from + 7.day).at_beginning_of_week
              when 'day'
                @periods << "#{date_from.to_date}"
                date_from = date_from + 1.day
              end
            end
          end
        end
      end
  end
end
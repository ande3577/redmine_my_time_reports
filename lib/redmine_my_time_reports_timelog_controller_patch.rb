module RedmineMyTimeReportsTimelogControllerPatch

  def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        
        before_filter :authorize_my_reports, :only => [:my_details, :my_report]
        accept_rss_auth :index, :my_details
        accept_api_auth :index, :my_details, :show, :create, :update, :destroy
        before_filter :authorize, :except => [:new, :index, :my_details, :report, :my_report]
          
        before_filter :find_optional_project, :only => [:index, :my_details, :report, :my_report]
        before_filter :get_optional_user, :only => [:index, :my_details, :report, :my_report] 
      end
  end
          
  module ClassMethods
  end
  
  module InstanceMethods
    def my_details
      sort_init 'spent_on', 'desc'
      sort_update 'spent_on' => ['spent_on', "#{TimeEntry.table_name}.created_on"],
                  'user' => 'user_id',
                  'activity' => 'activity_id',
                  'project' => "#{Project.table_name}.name",
                  'issue' => 'issue_id',
                  'hours' => 'hours'
  
      retrieve_date_range
  
      scope = TimeEntry.visible.spent_between(@from, @to).where(:user_id => @user.id)
      if @issue
        scope = scope.on_issue(@issue)
      elsif @project
        scope = scope.on_project(@project, Setting.display_subprojects_issues?)
      end
  
      respond_to do |format|
        format.html {
          # Paginate results
          @entry_count = scope.count
          @entry_pages = ActionController::Pagination::Paginator.new self, @entry_count, per_page_option, params['page']
          @entries = scope.all(
            :include => [:project, :activity, :user, {:issue => :tracker}],
            :order => sort_clause,
            :limit  =>  @entry_pages.items_per_page,
            :offset =>  @entry_pages.current.offset
          )
          @total_hours = scope.sum(:hours).to_f
  
          render "index"
        }
        format.api  {
          @entry_count = scope.count
          @offset, @limit = api_offset_and_limit
          @entries = scope.all(
            :include => [:project, :activity, :user, {:issue => :tracker}],
            :order => sort_clause,
            :limit  => @limit,
            :offset => @offset
          )
          render "index"
        }
        format.atom {
          entries = scope.all(
            :include => [:project, :activity, :user, {:issue => :tracker}],
            :order => "#{TimeEntry.table_name}.created_on DESC",
            :limit => Setting.feeds_limit.to_i
          )
          render_feed(entries, :title => l(:label_spent_time))
        }
        format.csv {
          # Export all entries
          @entries = scope.all(
            :include => [:project, :activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
            :order => sort_clause
          )
          send_data(entries_to_csv(@entries), :type => 'text/csv; header=present', :filename => 'timelog.csv')
        }
      end
    end
    
    def my_report
      retrieve_date_range
      @report = Redmine::Helpers::MyTimeReport.new(@project, @issue, params[:criteria], params[:columns], @from, @to, @user)
  
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.csv  { send_data(report_to_csv(@report), :type => 'text/csv; header=present', :filename => 'timelog.csv') }
      end
    end

  end

  def authorize_my_reports
    if params[:action] == :my_details
      authorize_global(params[:controller], :index)
    elsif params[:action] == :my_report
      authorize_global(params[:controller], :report)
    end
  end
    
  def get_optional_user
    @user = User.find(params[:user_id]) unless params[:user_id].nil?
  end
  
end
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  helper_method :admin_user?
  helper_method :shib_auth_url
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
 
  private 
  # change the condition for your environment
  def admin_user?
    session[:user][:uid] == 'akiyama'
  end

  def redirect_back_or_default
    redirect_to(request.referer || course_path)
  end

  def shib_auth_url
    if RAILS_ENV == 'production'
      "/presence_checker/auth/shibboleth"
    else
      "/auth/shibboleth"
    end
  end

  def authenticate!
    if session[:user].nil?
      session[:return_url] = request.url
      redirect_to shib_auth_url and return
    end
    session[:return_url] = nil
  end

  def check_admin
    if !admin_user?
      flash[:notice] = "This page requires admin role."
      redirect_back_or_default and return
    end
  end
end

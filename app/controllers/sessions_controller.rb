class SessionsController < ApplicationController
  def create
    session[:user] = {
      :login => request.env["omniauth.auth"]["uid"],
      :name => request.env["omniauth.auth"]["uid"],
      :email => request.env["omniauth.auth"]["uid"]
    }
    redirect_to session[:return_url], :flash => {:notice => "Welcome #{session[:user][:name]}"}
  end

  def destroy
    session[:user] = nil
    redirect_to root_url, :flash => {:notice => "You have been successfuly signed out"}
  end

  def failure
    redirect_to root_url, :flash => {:error => "Could not log you in. #{params[:message]}"}
  end
end

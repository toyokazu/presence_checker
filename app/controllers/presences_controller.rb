# -*- coding: utf-8 -*-
require 'ipaddr'
class PresencesController < ApplicationController
  before_filter :authenticate!

  def index
    if params[:lecture_id]
      @lecture = Lecture.find(params[:lecture_id])
    else
      @lecture = Lecture.first(:conditions => ['description = ?', params[:lect]])
    end
    if admin_user?
      @presences = Presence.joins(:lecture).with_course_id(params[:course_id]).with_lecture_id(params[:lecture_id]).with_lecture_description(params[:lect])
    else
      @presences = Presence.joins(:lecture).with_course_id(params[:course_id]).with_lecture_id(params[:lecture_id]).with_lecture_description(params[:lect]).where(:login => session[:user][:uid])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @presences }
    end
  end

  def show
    @presence = Presence.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @presence }
    end
  end

  # If you want to use this system together with Moodle,
  # you have to create Web link to /presences/new in your Moodle course.
  # And you also have to specify extended parameters as follows:
  #
  #  login = User - User Name
  #  name = User - Sir & Given Name
  #  mail = User - Mail Address
  #  moodle_course_id = Course - id
  #
  # Assumed new window size (width, height) = (800, 600) for default css (precense_checker.css).
  #  
  # You can also register presence without Moodle.
  # This function is basiclly for the students unregistered to the Moodle.
  #
  # GET /presences/new
  # GET /courses/1/presences/new
  def new
    @presence = init_presence(Presence.new(:login => params[:login],
                                           :name => params[:name],
                                           :mail => params[:mail]))
    if @presence.nil?
      return false
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @presence }
    end
  end

  def create
    @presence = init_presence(Presence.new(presence_params))
    if @presence.nil?
      return false
    end
    respond_to do |format|
      begin
        if @presence.save
          flash[:notice] = t('presences.notices.registration_finished')
          format.html { redirect_to(@presence) }
          format.xml  { render :xml => @presence, :status => :created, :location => @presence }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @presence.errors, :status => :unprocessable_entity }
        end
      rescue => error
        flash[:notice] = t('presences.notices.already_registered')
        format.html { render :action => "new" }
        format.xml  { render :xml => @presence.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def init_presence(presence)
    remote_addr = remote_address
    if !ip_addr_check(IPAddr.new(remote_addr))
      redirect_to root_url, :flash => {:error => t('presences.errors.execute_under_the_specified_condition')} and return nil
    end
    presence.ip_addr = remote_addr
    # presence registration from Moodle (new action)
    if action_name == 'new' && !params[:moodle_course_id].nil?
      # find Course related to the moodle course id
      presence.course = Course.where(moodle_id: params[:moodle_course_id]).first
      if presence.course.nil?
        redirect_to root_url, :flash => {:error => t('presences.errors.valid_moodle_course_id_is_not_specified')} and return nil
      end
    else
      # local presence registration (for students unregistered to Moodle, new action)
      # or create action
      if action_name == 'new'
        # new action
        if !params[:course_id].nil?
          presence.course = Course.find(params[:course_id])
        else
          redirect_to root_url, :flash => {:error => t('presences.errors.register_after_selecting_a_course')} and return nil
        end
        presence.login = session[:user][:uid]
      else
        # create action
        if presence.login != session[:user][:uid]
          redirect_to root_url, :flash => {:error => t('presences.errors.login_as_the_same_user_as_moodle')} and return nil
        end
      end
    end
    # find ongoing Lecture
    presence.lecture = Lecture.where(course_id: presence.course.id).where('start_time <= :time and end_time >= :time', :time => Time.now).first
    if presence.lecture.nil?
      redirect_to root_url, :flash => {:error => t('presences.errors.no_lecture_is_ongoing')} and return nil
    end
    # check ip address duplication
    owner = Presence.where('lecture_id = ? and ip_addr = ?', presence.lecture, presence.ip_addr).first
    if !owner.nil? && owner.login != presence.login
      presence.proxyed = true
    else
      presence.proxyed = false
    end
    presence
  end

  def remote_address
    #addr = nil
    #case RAILS_ENV
    #when "production"
    #  # assume that the rails server resides backend of the load balancer
    #  addr = request.env['HTTP_X_FORWARDED_FOR']
    #when "development", "test"
    #  addr = request.env['REMOTE_ADDR']
    #end
    #addr
    request.env['REMOTE_ADDR']
  end

  def ip_addr_check(remote_addr)
    net_addrs = APP_CONFIG[:networks].map {|addr| IPAddr.new(addr)}
    net_addrs.any? {|net_addr| net_addr.include?(remote_addr)}
  end

  def presence_params
    params.require(:presence).permit(:course_id, :login, :name, :mail, :proxyed)
  end

end

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
    @presence = init_presence(Presence.new(params[:presence]))
    if @presence.nil?
      return false
    end
    respond_to do |format|
      begin
        if @presence.save
          flash[:notice] = '出席登録が完了しました．'
          format.html { redirect_to(@presence) }
          format.xml  { render :xml => @presence, :status => :created, :location => @presence }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @presence.errors, :status => :unprocessable_entity }
        end
      rescue => error
        flash[:notice] = 'すでに登録済みです．'
        format.html { render :action => "new" }
        format.xml  { render :xml => @presence.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def init_presence(presence)
    remote_addr = remote_address
    if !ip_addr_check(IPAddr.new(remote_addr))
      redirect_to root_url, :flash => {:error => "指定された条件で実行してください．"} and return nil
    end
    presence.ip_addr = remote_addr
    # presence registration from Moodle (new action)
    if action_name == 'new' && !params[:moodle_course_id].nil?
      # find Course related to the moodle course id
      presence.course = Course.first(:conditions => ['moodle_id = ?', params[:moodle_course_id]])
      if presence.course.nil?
        redirect_to root_url, :flash => {:error => "有効な Moodle の Course ID が指定されていません．"} and return nil
      end
    else
      # local presence registration (for students unregistered to Moodle, new action)
      # or create action
      if action_name == 'new'
        # new action
        if !params[:course_id].nil?
          presence.course = Course.find(params[:course_id])
        else
          redirect_to root_url, :flash => {:error => "科目を選択してから出席登録してください．"} and return nil
        end
        presence.login = session[:user][:uid]
      else
        # create action
        if presence.login != session[:user][:uid]
          redirect_to root_url, :flash => {:error => "Moodle と同じユーザでログインしてください．"} and return nil
        end
      end
    end
    # find ongoing Lecture
    presence.lecture = Lecture.with_course_id(presence.course.id).ongoing(Time.now).first
    if presence.lecture.nil?
      redirect_to root_url, :flash => {:error => "Error: 現在開講中の講義がありません．"} and return nil
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

end

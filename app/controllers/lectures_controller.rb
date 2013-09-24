class LecturesController < ApplicationController
  before_filter :authenticate!
  before_filter :check_admin, :except => [:index]

  def index
    @course_id = params[:course_id]
    @lectures = Lecture.where(course_id: @course_id).sort {|a,b| a.start_time <=> b.start_time}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lectures }
    end
  end

  # GET /lectures/1
  # GET /lectures/1.xml
  def show
    @lecture = Lecture.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lecture }
    end
  end

  # GET /courses/1/lectures/new
  # GET /courses/1/lectures/new.xml
  def new
    @lecture = Lecture.new
    @lecture.course_id = params[:course_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lecture }
    end
  end

  # GET /lectures/1/edit
  def edit
    @lecture = Lecture.find(params[:id])
  end

  # POST /lectures
  # POST /lectures.xml
  def create
    @lecture = Lecture.new(lecture_params)

    respond_to do |format|
      if @lecture.save
        flash[:notice] = 'Lecture was successfully created.'
        format.html { redirect_to(@lecture) }
        format.xml  { render :xml => @lecture, :status => :created, :location => @lecture }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lecture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lectures/1
  # PUT /lectures/1.xml
  def update
    @lecture = Lecture.find(params[:id])

    respond_to do |format|
      if @lecture.update_attributes(lecture_params)
        flash[:notice] = 'Lecture was successfully updated.'
        format.html { redirect_to(@lecture) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lecture.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lectures/1
  # DELETE /lectures/1.xml
  def destroy
    @lecture = Lecture.find(params[:id])
    @course = @lecture.course
    @lecture.destroy

    respond_to do |format|
      format.html { redirect_to(course_lectures_url(@course)) }
      format.xml  { head :ok }
    end
  end

  private
  def lecture_params
    params.require(:lecture).permit(:course_id, :description, :start_time, :end_time)
  end
end

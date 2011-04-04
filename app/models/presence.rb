class Presence < ActiveRecord::Base
  belongs_to :course
  belongs_to :lecture

  def self.with_course_id(course_id)
    return where({}) if course_id.nil?
    where('lectures.course_id = ?', course_id)
  end

  def self.with_lecture_id(lecture_id)
    return where({}) if lecture_id.nil?
    where('lecture_id = ?', lecture_id)
  end

  def self.with_lecture_description(lecture_description)
    return where({}) if lecture_description.nil?
    where('lectures.description = ?', lecture_description)
  end
end

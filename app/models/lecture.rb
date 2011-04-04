class Lecture < ActiveRecord::Base
  belongs_to :course
  has_many :presences

  named_scope :with_course_id, lambda {|course_id|
    return {} if course_id.nil?
    {:conditions => ['course_id = ?', course_id]}
  }
  named_scope :ongoing, lambda {|time|
    return {} if time.nil?
    {:conditions => ['start_time <= :time and end_time >= :time', {:time => time.utc}]}
  }
end

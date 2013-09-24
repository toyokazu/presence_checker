class Lecture < ActiveRecord::Base
  belongs_to :course
  has_many :presences
end

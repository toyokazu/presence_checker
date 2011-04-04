class Course < ActiveRecord::Base
  has_many :lectures
end

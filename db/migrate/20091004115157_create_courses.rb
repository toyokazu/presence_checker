class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table :courses do |t|
      t.integer :moodle_id
      t.string :name
      t.timestamp :deleted_at

      t.timestamps
    end
  end

  def self.down
    drop_table :courses
  end
end

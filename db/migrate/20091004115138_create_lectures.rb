class CreateLectures < ActiveRecord::Migration
  def self.up
    create_table :lectures do |t|
      t.references :course
      t.string :description
      t.timestamp :start_time
      t.timestamp :end_time
      t.timestamp :deleted_at

      t.timestamps

    end
    add_index :lectures, :course_id
  end

  def self.down
    drop_table :lectures
  end
end

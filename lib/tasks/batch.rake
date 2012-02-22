# -*- coding: utf-8 -*-
require 'batch'
require 'csv'
require 'nkf'
namespace :batch do
  class AlreadyExistsError < StandardError
  end

  desc 'Count presence for each user and output as a csv format (source csv file could be specified by STUDENTS_CSV).'
  #task :count_presence => :conv_tsv_to_csv do
  task :count_presence => :environment do
    begin
      src_csv = ENV["STUDENTS_CSV"].nil? ? "#{Rails.root}/#{Batch::STUDENTS_CSV}" : "#{ENV["STUDENTS_CSV"]}"
      csv_students = CSV.read(src_csv)
      attrs_array = csv_students.shift
      attrs = {}
      attrs_array.each_with_index {|v, i| attrs[NKF.nkf('-Sw', v)] = i}
      db_students_own = Presence.count(:group => :login, :conditions => {:proxyed => false})
      db_students_proxyed = Presence.count(:group => :login, :conditions => {:proxyed => true})
      #Presence.count(:group => :login).sort.each {|a| puts "#{a[0].gsub(/g0/, '')}, #{a[1]}"}
      dst_tsv = ENV["RECORDS_CSV"].nil? ? "#{Rails.root}/#{Batch::RECORDS_CSV}" : "#{ENV["RECORDS_CSV"]}" 
      open(dst_tsv, "wb") do |fout|
        Batch::RECORD_ATTRS.each {|v| fout.print NKF.nkf('-Ws', "#{v},")}
        fout.print NKF.nkf('-Ws', "出席回数 (DB 本人),出席回数 (DB 代理),出席回数 (紙)\n")
        csv_students.each do |student|
          Batch::RECORD_ATTRS.each do |v|
            fout.print "#{student[attrs[v]]}, "
          end
          fout.print NKF.nkf('-Ws', "#{db_students_own["g" + student[attrs["学生証番号"]]]},#{db_students_proxyed["g" + student[attrs["学生証番号"]]]},\n")
        end
      end
    rescue => error
      puts "Error occurred in :count_presence."
      puts "#{error.class}: #{error.message}"
      puts error.backtrace
    end
  end
end

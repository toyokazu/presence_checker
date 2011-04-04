# -*- coding: utf-8 -*-
namespace :batch do
  require 'csv'
  # input CSV default name
  SRC_CSV="db/students.csv"
  # final results
  DST_CSV="db/records.csv"
  #ATTRS = ["セメスター", "入学年度", "学生証番号", "氏名", "ローマ字氏名"]
  ATTRS = ["セメ", "入学年度", "学生証番号", "漢字氏名", "カナ氏名"]

  class AlreadyExistsError < StandardError
  end

  desc 'Count presence for each user and output as a csv format (source csv file could be specified by SRC_CSV).'
  #task :count_presence => :conv_tsv_to_csv do
  task :count_presence => :environment do
    begin
      src_csv = ENV["SRC_CSV"].nil? ? "#{RAILS_ROOT}/#{SRC_CSV}" : "#{ENV["SRC_CSV"]}"
      csv_students = CSV.read(src_csv)
      attrs_array = csv_students.shift
      attrs = {}
      attrs_array.each_with_index {|v, i| attrs[NKF.nkf('-Sw', v)] = i}
      db_students_own = Presence.count(:group => :login, :conditions => {:proxyed => false})
      db_students_proxyed = Presence.count(:group => :login, :conditions => {:proxyed => true})
      #Presence.count(:group => :login).sort.each {|a| puts "#{a[0].gsub(/g0/, '')}, #{a[1]}"}
      dst_tsv = ENV["DST_CSV"].nil? ? "#{RAILS_ROOT}/#{DST_CSV}" : "#{ENV["DST_CSV"]}" 
      open(dst_tsv, "w") do |fout|
        ATTRS.each {|v| fout.print NKF.nkf('-Ws', "#{v},")}
        fout.print NKF.nkf('-Ws', "出席回数 (DB 本人),出席回数 (DB 代理),出席回数 (紙)\n")
        csv_students.each do |student|
          ATTRS.each do |v|
            fout.print "#{student[attrs[v]]}, "
          end
          fout.print NKF.nkf('-Ws', "#{db_students_own["g" + student[attrs["学生証番号"]]]},#{db_students_proxyed["g" + student[attrs["学生証番号"]]]},\r\n")
        end
      end
    rescue => error
      puts "Error occurred in :count_presence."
      puts "#{error.class}: #{error.message}"
      puts error.backtrace
    end
  end

  desc 'Delete db/students.csv.'
  task :delete_csv => :environment do
    begin
      File.delete("#{RAILS_ROOT}/#{DST_CSV}")
    rescue => error
      puts "Error occurred in :delete_csv."
      puts "#{error.class}: #{error.message}"
      puts error.backtrace
    end
  end

  desc 'Convert from Excel tsv to Ruby csv (source tsv file name should be specified by SRC_TSV).'
  task :conv_tsv_to_csv => :environment do
    begin
      raise AlreadyExistsError, "#{DST_CSV} is already exists." if File.exist?("#{RAILS_ROOT}/#{DST_CSV}")
      src_tsv = ENV["SRC_TSV"].nil? ? "#{RAILS_ROOT}/db/source.tsv" : "#{ENV["SRC_TSV"]}" 
      open(src_tsv) do |fin|
        open("#{RAILS_ROOT}/#{DST_CSV}", "w") do |fout|
          lines = fin.readlines
          lines.each do |line|
            fout.puts NKF.nkf('-Sw', "\"#{line.gsub(/\t/, '","').gsub(/\r\n/, '')}\"")
          end
        end
      end
    rescue AlreadyExistsError => error
      puts "#{error.class}: #{error.message}"
    rescue => error
      puts "Error occurred in :convert_csv."
      puts "#{error.class}: #{error.message}"
      puts error.backtrace
    end
  end
end

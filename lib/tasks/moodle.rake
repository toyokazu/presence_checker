# -*- coding: utf-8 -*-
namespace :moodle do
  require 'csv'
  # input CSV default name
  SRC_RECORD_CSV="db/records.csv"
  SRC_MOODLE_CSV="db/moodle.csv"
  # final results
  DST_CSV="db/tmp.csv"
  # assumed attributes (index: 0-5)
  ATTRS = ["名称", "IDナンバー", "開始日時", "受験完了", "所要時間", "評点/\d\d"]

  class AlreadyExistsError < StandardError
  end

  desc 'Extract results csv from moodle csv (SRC_MOODLE_CSV) by merging ID number with the result csv (SRC_RECORD_CSV).'
  task :merge_csv => :environment do
    begin
      src_record_csv = ENV["SRC_RECORD_CSV"].nil? ? "#{RAILS_ROOT}/#{SRC_RECORD_CSV}" : "#{ENV["SRC_RECORD_CSV"]}"
      src_moodle_csv = ENV["SRC_MOODLE_CSV"].nil? ? "#{RAILS_ROOT}/#{SRC_MOODLE_CSV}" : "#{ENV["SRC_MOODLE_CSV"]}"
      dst_csv = ENV["DST_CSV"].nil? ? "#{RAILS_ROOT}/#{DST_CSV}" : "#{ENV["DST_CSV"]}"

      # read record file
      csv_records = CSV.read(src_record_csv)
      record_attrs_array = csv_records.shift
      # order by student number
      csv_records = csv_records.sort {|a,b| a[1] <=> b[1]}

      # read moodle record file
      csv_moodles = CSV.read(src_moodle_csv)
      moodle_attrs_array = csv_moodles.shift
      moodle_attrs = []
      moodle_attrs_array.each_with_index do |v, i|
        label = NKF.nkf('-Sw', v)
        moodle_attrs << label
        if label =~ /評点\/\d\d/
          break
        end
      end
      csv_moodles = csv_moodles.sort {|a,b| a[1] <=> b[1]}
      open(dst_csv, "w") do |fout|
        fout.print NKF.nkf('-Ws', "#{moodle_attrs[0]},#{moodle_attrs[1]},#{moodle_attrs.last}\n")
        i = 0
        csv_moodles.each do |moodle|
          while true do
            break if i >= csv_records.size
            if csv_records[i][1].to_i < moodle[1].to_i
              fout.print "#{csv_records[i][4]},#{csv_records[i][1]},\r\n"
              i += 1
            elsif csv_records[i][1].to_i == moodle[1].to_i
              fout.print "#{moodle[0]},#{moodle[1]},#{moodle[moodle_attrs.size - 1]}\r\n"
              i += 1
              break
            else # csv_records[i][1].to_i > moodle[1].to_i
              break
            end
          end
        end
        while i < csv_records.size do
          fout.print "#{csv_records[i][4]},#{csv_records[i][1]},\r\n"
          i += 1
        end
      end
    rescue => error
      puts "Error occurred in moodle:merge_csv."
      puts "#{error.class}: #{error.message}"
      puts error.backtrace
    end
  end
end

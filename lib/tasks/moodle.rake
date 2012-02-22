# -*- coding: utf-8 -*-
namespace :moodle do
  require 'csv'
  require 'nkf'

  class AlreadyExistsError < StandardError
  end

  desc 'Extract results csv from moodle csv (MOODLE_RECORDS_CSV) by merging ID number with the result csv (RECORDS_CSV).'
  task :merge_csv => :environment do
    begin
      src_record_csv = ENV["RECORDS_CSV"].nil? ? "#{Rails.root}/#{Batch::RECORDS_CSV}" : "#{ENV["RECORDS_CSV"]}"
      src_moodle_csv = ENV["MOODLE_RECORDS_CSV"].nil? ? "#{Rails.root}/#{Batch::MOODLE_RECORDS_CSV}" : "#{ENV["MOODLE_RECORDS_CSV"]}"
      dst_csv = ENV["MERGED_RECORDS_CSV"].nil? ? "#{Rails.root}/#{Batch::MERGED_RECORDS_CSV}" : "#{ENV["MERGEDS_RECORDS_CSV"]}"

      # read record file
      csv_records = CSV.read(src_record_csv)
      record_attrs_array = csv_records.shift
      # order by student number
      csv_records = csv_records.sort {|a,b| a[2].to_i <=> b[2].to_i}
# for debug     
#puts "csv_records: #{csv_records}"

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
      csv_moodles = csv_moodles.sort {|a,b| a[1].to_i <=> b[1].to_i}
# for debug     
#puts "csv_moodles: #{csv_moodles}"
#puts "moodle_attrs: #{moodle_attrs}"
      csv_records_ids = []
      moodle_ids = []
      open(dst_csv, "wb") do |fout|
        fout.print NKF.nkf('-Ws', "#{moodle_attrs[0]},#{moodle_attrs[1]},#{moodle_attrs.last}\r\n")
        i = 0
        csv_moodles.each do |moodle|
          while true do
            # FIXME
            # csv_records[i][2] the index of csv_records may be changed
            # by the spec change of the record registration system.
            # so thus, it must be treated by the column name
            break if i >= csv_records.size
# for debug     
puts "csv_records[#{i}][2]: #{csv_records[i][2]}"           
puts "moodle[1]: #{moodle[1]}"
            csv_records_ids << csv_records[i][2].to_i
            if csv_records[i][2].to_i < moodle[1].to_i
              fout.print "#{csv_records[i][4]},#{csv_records[i][2]},\r\n"
              i += 1
            elsif csv_records[i][2].to_i == moodle[1].to_i
              fout.print "#{moodle[0]},#{moodle[1]},#{moodle[moodle_attrs.size - 1]}\r\n"
              i += 1
              break
            else # csv_records[i][2].to_i > moodle[1].to_i
              break
            end
          end
          moodle_ids << moodle[1].to_i
        end
        while i < csv_records.size do
          fout.print "#{csv_records[i][4]},#{csv_records[i][2]},\r\n"
          i += 1
        end
      end
# for debug
p moodle_ids - csv_records_ids
puts "count (moodle_ids - csv_records_ids): #{(moodle_ids - csv_records_ids).size}"
p csv_records_ids - moodle_ids
puts "count (csv_records_ids - moodle_ids): #{(csv_records_ids - moodle_ids).size}"
    rescue => error
      puts "Error occurred in moodle:merge_csv."
      puts "#{error.class}: #{error.message}"
      puts error.backtrace
    end
  end
end

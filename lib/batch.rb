# -*- coding: utf-8 -*-
class Batch
  STUDENTS_CSV="db/students.csv"
  # final results
  RECORDS_CSV="db/records.csv"
  #ATTRS = ["セメスター", "入学年度", "学生証番号", "氏名", "ローマ字氏名"]
  RECORD_ATTRS = ["セメ", "入学年度", "学生証番号", "漢字氏名", "カナ氏名"]

  MOODLE_RECORDS_CSV="db/moodle.csv"
  # final results
  MERGED_RECORDS_CSV="db/merged.csv"
  # assumed attributes (index: 0-5)
  MOODLE_ATTRS = ["名称", "IDナンバー", "開始日時", "受験完了", "所要時間", "評点/\d\d"]
end

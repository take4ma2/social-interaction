#
# Crawley Social Interaction test result analyser
# Created at 2019-03-20
#         by Matsubara T.
#
require 'csv'

module SocialInteraction
  class SiData
    attr_accessor :subjects
    attr_accessor :path
    attr_accessor :lines

    def initialize(file)
      @subjects = []
      @path = file
      raise 'Social interaction result data file is not assigned' if @path.nil?
      raise 'Social interaction result data file is not found' unless File.exist? @path
      parse File.open(@path)
      output
    end

    def parse(f)
      @lines = CSV.parse(f.read, col_sep: "\t")
      parse_result
    end

    # データの読み込みメイン
    def parse_result
      err_index = find_all('Abort')
      if err_index.size > 0 then
        error_exit "Cannot analyze CSI data (Line: #{err_index[0]+1})"
      end
      index = find_all '#Trial Sequence Information'
      data = []
      index.each do |indice|
        channels = channels_in_trial(indice)
        # 試行内のチャンネル数によって読み込む行の開始位置と終了位置が変動する(2020-07-02)
        (indice+channels*3+3 .. indice+channels*3+2+channels*3).to_a.each { |i| data << SiDatum.parse(@lines[i]) }
      end

      subjects = []
      data.each {|d| subjects << d.subject}
      #subjects.sort!.uniq!
      subjects.uniq!
      subjects.each {|s| @subjects << Subject.parse(data.select{ |d| d.subject == s })} 
    end
    
    # 1試行中で使用したチャンネル数の取得(2020-07-02)
    def channels_in_trial(index)
      i = index+2
      channels = 0
      while @lines[i][0].match(/Channel/).nil?
        channels = @lines[i][0].to_i > channels ? @lines[i][0].to_i : channels
        i += 1
      end
      channels
    end
    
    def find_all(string)
      @lines.map.with_index{ |e,i| e.index(string).nil? ? nil : i }.compact
    end

    def error_exit(message)
      output_path = 'csi_ts.csv'
      File.open(output_path, 'w') do |f|
        f.puts message
      end
      exit!
    end

    def output
      output_path = File.basename(@path).sub(/\.txt$/, '_csi.csv')
      ary = [['subject','left cage(empty session)','right cage(empty session)','empty cage(object session)', 'object cage', 'empty cage(stranger session)','stranger cage']]
      @subjects.each {|s| ary << s.output }
      CSV.open(output_path, 'w') {|csv|
       ary.each { |e| csv << e }
      }
    end
  end
  
  class SiDatum
    INTRUDER =['Empty','Object','Stranger']
    attr_accessor :right, :left
    attr_accessor :subject, :st_left, :st_right
    attr_accessor :pattern    
    def self.parse(ary)
      self.new ary
    end

    def initialize(ary)
      @subject = ary[1]
      @left = INTRUDER.index ary[2]
      @right = INTRUDER.index ary[3]
      @st_left = ary[9]
      @st_right = ary[10]
      @pattern = INTRUDER[[@left,@right].max]
    end
  end 

  class Subject
    attr_accessor :subject
    attr_accessor :empty_left, :empty_right
    attr_accessor :object_placed, :object_not_placed
    attr_accessor :stranger_placed, :stranger_not_placed
    
    def self.parse(data)
      self.new data
    end

    def initialize(data)
      @subject = data[0].subject
      data.each {|d| set_data d }
    end

    def set_data(datum)
      if datum.pattern == "Empty" then
        @empty_left = datum.st_left
        @empty_right = datum.st_right
      elsif datum.pattern == "Object" then
        datum.left  == 0 ? @object_not_placed = datum.st_left  : @object_placed = datum.st_left
        datum.right == 0 ? @object_not_placed = datum.st_right : @object_placed = datum.st_right
      elsif datum.pattern == "Stranger" then
        datum.left  == 0 ? @stranger_not_placed = datum.st_left  : @stranger_placed = datum.st_left
        datum.right == 0 ? @stranger_not_placed = datum.st_right : @stranger_placed = datum.st_right
      end
    end

    def output
      [@subject, @empty_left, @empty_right, @object_not_placed, @object_placed, @stranger_not_placed, @stranger_placed]
    end
  end

  def VERSION
    '1.1.0 (Assigns outpt file name)'
  end
  module_function :VERSION
end

puts "Social interaction test result analyzer [v. #{SocialInteraction.VERSION}]"

SocialInteraction::SiData.new ARGV[0]

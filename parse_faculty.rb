require "getscore"
require "erb"


class Students
  attr_accessor :all

  def initialize
    str = File.read("./vendor/sort_by_xh")
    @all = eval(str)
  end
end


class ParseFaculty
  attr_accessor :students, :classes, :a_class_user_arr

  def initialize(students)
    @students = students
    @classes = []
    @a_class_user_arr = []
    @result_file_str = ""
  end

  def collect_a_class_array(class_name)
    @class_name = class_name
    @students.each do |u|
      @a_class_user_arr.push(u) if u[:bj] == class_name
    end
  end


  def parse_downloaded_faculty_score_txt
    File.foreach("html_file.tmp") do |line|

      line = line.force_encoding("utf-8").split("\t")
      next if line[0].size < 7 || line[2].size < 3

      xh = line[0]
      lesson_name = line[3]
      @classes.push(lesson_name)
      score   = line[4]

      @students.each do |student|
        if student[:xh] == xh
          student[lesson_name] = score
        end
      end
    end
    @classes.uniq!
  end

  def find_ones_score(*args)
    @students.each do |u|
      if u[args[0].to_sym] == args[1]
        u.each_pair do |key, value|
          case key.to_s
          when 'xm','xb','xh','bj','zy','nj'
            puts u[key]
          else
            utf8_num = (key.bytesize + key.length)/2
            blanks = " " * (30 - utf8_num)
            print "#{key}#{blanks}#{value}\n"
          end
        end
      end
    end
  end

  def print_a_csv_list_user(user_arr)
    append_str("\t\t")
    @classes.each {|c_name| append_str("#{c_name}\t")}
    append_str("\n")

    user_arr.each do |u|
      append_str("#{u[:xh]}\t#{u[:xm]}\t")
      @classes.each do |c_name|
        has = 0
        u.each_pair do |key, value|
          if key.to_s == c_name
            has = 1
            append_str("#{u[key]}\t")
          end
        end
        if has == 0
          append_str("\t")
        else
          has = 0
        end
      end
      append_str("\n")
    end
    delete_white_column(@result_file_str)
  end

  def append_str(str)
    @result_file_str += str
  end


  def delete_white_column(str)
    arr = str.split("\n").map { |e| e.split("\t") }
    has_array = []
    str = []
    # 置换列与行
    arr = arr[0].zip(*arr[1..-1])
    arr.each do |column|
      column.each_with_index do |cell, index|
        next if index == 0
        if cell && cell.length > 0
          has_array << column
          break
        end
      end
    end
    #置换回来
    has_array = has_array[0].zip(*has_array[1..-1])

    table_str = gen_table(has_array)

    File.write("./tmp/#{@class_name}_table.html", table_str)
    table_str
  end

  def gen_table(arr)
    str = ""
    arr.each_with_index do |line, index|
      line.map! do |x|
        if index == 0
          "<th>#{x}</th>"
        else
          "<td>#{x}</td>"
        end
      end
      line.unshift("<tr>")
      line.push("</tr>")
    end

    arr[0].unshift "<div class='a-class'><h1>#{@class_name}</h1><table class='table table-bordered table-hover'><thead>"
    arr[0].push "</thead><tbody>"
    arr.push ["</tbody></table></div>"]

    table = arr.join
  end
end







loop do
  me = CheckOne.new("2012021713", "1")
  me.get_score
  if me.different?
    page = me.get_whole_page
    File.open("class_page.tmp", "w") { |file| file.write page }
    sleep 15

    try_download = lambda do
      15.times do |index|
        if "SUCCESS" == me.download_text(page)
          return "TRY SUCCESS"
        end
        puts "#{index} fail"
        sleep(3)
      end
      return "TRY FAILURE"
    end

    try_sign = try_download.call

    if try_sign == "TRY FAILURE"
      sleep(2*60*60)
      next
    elsif try_sign == "TRY SUCCESS"
      table_html = []
      students = Students.new.all

      parse = ParseFaculty.new(students)
      parse.collect_a_class_array("电信12-03")
      parse.parse_downloaded_faculty_score_txt
      table_html << parse.print_a_csv_list_user(parse.a_class_user_arr)

      parse = ParseFaculty.new(students)
      parse.collect_a_class_array("电信12-01")
      parse.parse_downloaded_faculty_score_txt
      table_html << parse.print_a_csv_list_user(parse.a_class_user_arr)

      file_ctime = Time.now
      html  = ERB.new(File.read("./template/application.html")).result binding
      File.write("index.html", html)
    end
    sleep(60*60)
  else
    puts "not different"
    sleep(60*60)
  end
end



require "getscore"
require "erb"


class Students
  attr_accessor :all

  def initialize
    str = File.read("./vendor/sort_by_xh")
    @all = eval(str)
  end
end


module GetClassTxt
  def get_whole_page
    puts "get faculty score"
    request = Net::HTTP::Post.new('/reportFiles/zhjwcx/syxqcjxx/zhjwcx_syxqcjxx_jtcjcx.jsp')
    request['Cookie'] = @session
    request.set_form_data("xsh"=>"05", "zxjxjhh"=>"2014-2015-2-1", "bjh"=>"")
    begin
      response = @http.request(request)
    rescue Exception => e
      log_out
      exit
    end
    body = response.body.force_encoding('gbk').encode('utf-8')
  end


  def download_text(html)
    puts "download_text"
    html.match /saveAsText.*\s?\{\s+.*src.*"(.*)";$/
    begin
      request = Net::HTTP::Get.new(URI($1.to_s))
      @http.request(request) do |response|
        return unless response.is_a?(Net::HTTPSuccess)
        File.open("html_file.tmp", "w") do |file|
          response.read_body do |segment|
            file.write(segment)
          end
        end
      end
    ensure Exception => e
      log_out
    end
    "SUCCESS"
  end

  def log_out
    request = Net::HTTP::Post.new('/logout.do')
    request['Cookie'] = @session
    request.set_form_data("loginType"=>"platformLogin")
    response = @http.request(request)
    puts "logout code: #{response.code}"
  end
end


class CheckOne
  attr_accessor :session

  def initialize(username, passwd)
    @username = username
    @passwd   = passwd
    @port     = 80
    @session  = nil
    #@user_agent = {
    #      'User-Agent' => "score-bot, just for test"
    #}

    check_internet
    @http = Net::HTTP.new(@host, @port)
  end

  def check_internet
    #hosts = ["60.219.165.24", "192.168.11.239"]
    #threads = []
    #hosts.each do |host|
    #  threads << Thread.new do
    #    uri = URI("http://#{host}/loginAction.do")
    #    response = Net::HTTP.post_form(uri, 'zjh' => @username, 'mm' => @passwd)
    #    return if "200" != response.code
    #    threads.each { |thread| Thread.kill(thread) if thread != Thread.current }
    #    @host = host
    #    @session = response["set-cookie"]
    #  end
    #end
    #threads.each(&:join)
    host = "60.219.165.24"
    uri = URI("http://#{host}/loginAction.do")
    response = Net::HTTP.post_form(uri, 'zjh' => @username, 'mm' => @passwd)
    return if "200" != response.code
    @host = host
    @session = response["set-cookie"]
  end

  def get_session
    puts "force get session, |this method should not run|"
    request = Net::HTTP::Post.new('/loginAction.do')
    request.set_form_data({ 'zjh' => @username, 'mm' => @passwd })
    response = @http.request(request)

    raise "can't get session"  if !response.code == '200'
    @session = response["set-cookie"]
  end

  def get_score
    puts "get my score"
    raise "get_session first OR no session" if @session == nil
    request = Net::HTTP::Get.new('/bxqcjcxAction.do')
    request['Cookie'] = @session
    response = @http.request(request)
    @body = response.body.force_encoding('gbk').encode('utf-8').gsub(/\s/,"")

    self
  end

  def different?
    puts "diff?"
    last = File.exist?("last_digest.tmp") ? File.read("last_digest.tmp") : nil
    now = Digest::SHA2.hexdigest(@body)

    if last == now
      return false
    else
      puts "It's different now!"
      File.open("last_digest.tmp", "w") { |file| file.print now }
      return true
    end
  end

  def parse_html
    puts "parse my score"
    @body =~ /thead(.*)<\/TABLE/
    arr = $1.scan(/>(.{0,15})<\/td/).map(&:first)
    max_ulen = arr.map(&:ulen).max
    puts "---------------------------------------------------"
    arr.each_slice(7) do |row|
      printf("%-9s %-4s %-s %s %-5s %-4s %-4s\n",row[0],row[1],row[2],(" "*(max_ulen - row[2].ulen)),row[4],row[5],row[6])
    end
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
  me = CheckOne.new("2012021712", "1")
  me.get_score
  if me.different?
    page = me.get_whole_page
    File.open("class_page.tmp", "w") { |file| file.write page }
    sleep 25

    try_download = lambda do
      15.times do |index|
        if "SUCCESS" == me.download_text(page)
          puts "TRY SUCCESS"
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



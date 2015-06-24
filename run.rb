require "getscore"
require "erb"
require "sinatra"

require "./lib/parse_faculty"



class Students
  attr_accessor :all

  def initialize
    str = File.read("./vendor/sort_by_xh").force_encoding("utf-8")
    @all = eval(str)
  end
end



class CheckOne
  def check_internet
    host = "60.219.165.24"
    uri = URI("http://#{host}/loginAction.do")
    response = Net::HTTP.post_form(uri, 'zjh' => @username, 'mm' => @passwd)
    return if "200" != response.code
    @host = host
    @session = response["set-cookie"]
  end
end


def doOneClass(students, class_name)
  parse = ParseFaculty.new(students)
  parse.collect_a_class_array(class_name)
  parse.parse_downloaded_faculty_score_txt
  parse.print_a_csv_list_user(parse.a_class_user_arr)
end




$index_html = nil


Thread.new do
loop do
  me = CheckOne.new("2012021712", "1")
  me.get_score
  if me.different?
    page = me.get_whole_page
    sleep 15

    try_download = lambda do
      5.times do |index|
        if "SUCCESS" == me.download_text(page)
          me.log_out
          puts "TRY SUCCESS"
          return "TRY SUCCESS"
        end
        sleep(3)
      end
      puts "TRY FAILURE"
      return "TRY FAILURE"
    end

    try_sign = try_download.call

    if try_sign == "TRY FAILURE"
      sleep(2*60*60)
      next
    elsif try_sign == "TRY SUCCESS"
      table_html = []
      students = Students.new.all

      table_html << doOneClass(students, "电信12-03")
      table_html << doOneClass(students, "电信12-01")


      file_ctime = Time.now.getlocal("+08:00").to_s
      html  = ERB.new(File.read("./template/application.html").force_encoding("utf-8")).result binding

      $index_html = html
      #File.open("index.html", "w") { |f| f.write(html) }
    end
    sleep(3*60*60)
  else
    puts "not different"
    sleep(2*60*60)
  end
end
end

Thread.new do
  loop do
    Net::HTTP.get(URI("http://getscore.herokuapp.com/"))
    sleep(60*20)
  end
end


$Heroku_500 = File.read("./template/heroku_500.html").force_encoding("utf-8")




get '/' do
  $index_html || $Heroku_500
end

set :public_folder, './public'


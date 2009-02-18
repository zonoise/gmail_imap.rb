#!/usr/local/bin/ruby

require 'gmail_imap'
require 'readline'


print "input your old gmail account\n> "
src_user = STDIN.readline.chomp
print "input password\n> "
system "stty -echo"
src_password = STDIN.readline.chomp
system "stty echo"
print "\n"

print "input your new gmail account\n> "
dest_user = STDIN.readline.chomp
print "input password\n> "
system "stty -echo"
dest_password = STDIN.readline.chomp
system "stty echo"
print "\n"

src_gmail = GMail.new(src_user, src_password)
dest_gmail = GMail.new(dest_user, dest_password)

src_gmail.labels.each do |dir|
  puts "COPY #{dir.name_ja}..."
  if dir.abstruct?
    puts "EMPTY DIR"
  else
    if dest_gmail.list("",dir.name).nil?
      dest_gmail.create(dir.name)
      puts "CREATE DIR #{dir.name_ja}"
    end
    src_gmail.mails(dir.name).each do |mail|
      retry_flag = true
      while(retry_flag)
        begin
          retry_flag = false
          body = src_gmail.body(dir.name, mail)
          dest_gmail.append(dir.name, body, mail.attr["FLAGS"], mail.utime)
          sleep(1)
        rescue
          puts "retrying..."
          retry_flag = true
        end
      end
    end      
  end
end

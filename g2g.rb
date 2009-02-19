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

begin
  src_gmail = GMail.new(src_user, src_password)
rescue
  print '[ERROR] error in connect src'
  exit
end

begin
  dest_gmail = GMail.new(dest_user, dest_password)
rescue
  print '[ERROR] error in connect dest'
  exit
end

retry_max = 3

src_gmail.labels.each do |dir|
  unless dir.abstruct?
    puts "copying #{dir.name_ja}..."
    count = [0,0,0]
    
    if dest_gmail.list("",dir.name).nil?
      dest_gmail.create(dir.name)
      puts " create label #{dir.name_ja}"
    end
    exist_mails = dest_gmail.mails(dir.name).collect do |mail|
      mail.message_id
    end

    src_gmail.mails(dir.name).each do |mail|
      unless exist_mails.include? mail.message_id
        retry_flag = true
        retrying_count = 0
        while(retry_flag && retrying_count < retry_max)
          begin
            retry_flag = false
            body = src_gmail.body(dir.name, mail)
            dest_gmail.append(dir.name, body, mail.attr["FLAGS"], mail.utime)
            sleep(1)
            count[0] = count[0].succ
            print 'o'
          rescue
            retry_flag = true
            retrying_count = retrying_count.succ
          end
        end
        if(retrying_count >= retry_max)
          print 'x'
          count[2] = count[2].succ
        end
      else
        print 's'
        count[1] = count[1].succ
      end
    end
    puts "  copy finished; copied: #{count[0]}, skipped: #{count[1]}, errored: #{count[2]}"
  end
end

src_gmail.close
dest_gmail.close

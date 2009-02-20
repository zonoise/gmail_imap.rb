#!/usr/local/bin/ruby

require 'gmail_imap'

src_user = ''
src_password = ''
dest_user = ''
dest_password = ''

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
    puts "exist mail loaded; #{exist_mails.length} mails."
    dest_gmail.select(dir.name)
    src_gmail.mails(dir.name).each do |mail|      
      unless exist_mails.include? mail.message_id
        retry_flag = true
        retry_count = 0
        while(retry_flag && retry_count < retry_max)
          begin
            retry_flag = false
            body = src_gmail.body(dir.name, mail)
            dest_gmail.append(dir.name, body, mail.attr["FLAGS"], mail.utime)
            sleep(1)
          rescue
            retry_flag = true
            retry_count = retry_count.succ
          end
        end
        if retry_flag
          print 'x'
          count[2] = count[2].succ
        else
          print 'o'
          count[0] = count[0].succ
        end
      else
        print 's'
        count[1] = count[1].succ
      end
      $stdout.flush
    end
    puts "  copy finished; copied: #{count[0]}, skipped: #{count[1]}, failed: #{count[2]}"
  end
end

#src_gmail.close
#dest_gmail.close

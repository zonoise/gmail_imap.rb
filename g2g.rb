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
    
    exist_mails = {}
    dest_gmail.mails(dir.name).each do |mail|
      exist_mails[mail.message_id] = mail
    end

    puts "exist mail loaded; #{exist_mails.length} mails."
    dest_gmail.select(dir.name)
    i = 0
    change_flag = {}
    while(mails = src_gmail.mails_body(dir.name, i))
      i = i.succ
      mails.each do |mail|
        exist_mail = exist_mails[mail.message_id]
        if exist_mail.nil? || exist_mail.utime != mail.utime
          retry_flag = true
          retry_count = 0
          while(retry_flag && retry_count < retry_max)
            begin
              retry_flag = false
              dest_gmail.append(dir.name, mail.to_mail, mail.flags, mail.utime)
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
          if exist_mail.flags != mail.flags
            change_flag[mail.flags] = [] if change_flag[mail.flags].nil?
            change_flag[mail.flags] << exist_mail.uid
          end
          print 's'
          count[1] = count[1].succ
        end
        $stdout.flush
      end
    end
    p change_flag
    change_flag.to_a.each do |changes|
      dest_gmail.uid_store(changes[1], "FLAGS", changes[0])
    end
    
    puts "  copy finished; copied: #{count[0]}, skipped: #{count[1]}, failed: #{count[2]}"
  end
end

#src_gmail.close
#dest_gmail.close

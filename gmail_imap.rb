require 'net/imap'
require 'time'

class GMail < Net::IMAP
  def initialize(user = nil, password = nil)
    begin
      super('imap.gmail.com', 993, true)
    rescue
      raise 'connect failed'
    end
    if !(user.nil? && password.nil?)
      login(user, password)
    end
    @_message_length = {}
    @labels = load_labels
  end
  
  def labels
    @labels
  end

  def mails(label)
    #GMail::MailList.new(self, label)
    select(label)
    ret = fetch(1..-1, "ALL")
    ret.nil? ? [] : ret
  end

  def body(label, mail)
    select(label)
    fetch(mail.seqno, "RFC822")[0].attr["RFC822"]
  end
  
  def message_length(label)
    load_message_length(label) if @_message_length[label].nil?
    @_message_length[label]
  end
  
  class MailList
    include Enumerable
    def initialize(gmail, label)
      @gmail = gmail
      @label = label
      @len = @gmail.message_length(@label)
      @count = 1
    end
    
    def each
      data = _next
    end
    
    def _next
      @gmail.select(@label)
      data = @gmail.fetch(@count..1, "ALL")
      @count.succ!
      data
    end
  end  
  
  private 
  def load_message_length(label)
    select(label)
    @_message_length[label] = responses["EXISTS"]
  end

  def load_labels(dir = '')
    children(dir)
  end
  
  def children(dir)
    list = []
    tmp = list('',"#{dir}/%")
    tmp.each do |l|
      if !l.abstruct?
        list.push l
      end
      if l.has_children?
        list.push children(l.name)
      end
    end
    list.flatten
  end
  

end

class Net::IMAP::MailboxList
  def abstruct?
    attr.include? :Noselect
  end

  def has_children?
    attr.include? :Haschildren
  end
  
  def message_length
    
  end

  def name_ja
    Net::IMAP.decode_utf7 name
  end
end

class Net::IMAP::FetchData
  def to_mail
    env = attr["ENVELOPE"]
    line = []
    line.push "Date: #{env.date}"
    line.push "Subject: #{env.subject}"
    to = env.to.collect{|m| "#{m.mailbox}@#{m.host}"}.join(',')
    from = env.from.collect{|m| "#{m.mailbox}@#{m.host}"}.join(',')
    line.push "From: #{from}"
    line.push "To: #{to}"
    unless env.cc.nil?
      cc = env.cc.collect{|m| "#{m.mailbox}@#{m.host}"}.join(',')
      line.push "Cc: #{cc}" 
    end
    unless env.bcc.nil?
      bcc = env.bcc.collect{|m| "#{m.mailbox}@#{m.host}"}.join(',')
      line.push "Bcc: #{bcc}" 
    end

    line.push ""
    line.push "hoge"
    line.join "\n"
  end
  
  def utime
    Time.parse(attr["INTERNALDATE"])
  end
  
  def body
    
  end
end


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
  
  def name_ja
    Net::IMAP.decode_utf7 name
  end
end

class Net::IMAP::FetchData
  def message_id
    attr["ENVELOPE"].message_id
  end
  
  def utime
    Time.parse(attr["INTERNALDATE"])
  end
end


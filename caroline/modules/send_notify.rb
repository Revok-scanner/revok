class NotifySender

  def send_msg(title="", body="")
# TODO send a pop-up notification
    begin
      system("notify-send '#{title}' '#{body}' -t 0")
    rescue =>exp
      log exp.to_s
    end
  end

end

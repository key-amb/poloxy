class Poloxy::Deliver::HttpPost < Poloxy::Deliver::Base

  # @param message [Poloxy::DataModel::Message]
  def deliver message
    body = create_body message
    do_post message, body
  end

  private

  # @param message [Poloxy::DataModel::Message]
  def create_body message
    message.body
  end

  # @param message [Poloxy::DataModel::Message]
  # @param body [String] POST Body
  def do_post message, body
    url  = URI.parse(message.address)
    post = Net::HTTP::Post.new(url.path).tap do |post|
      post['Content-Type'] = 'application/json'
      post.body = body
    end
    http = Net::HTTP.new(url.host, url.port).tap do |http|
      http.use_ssl = true
      http.set_debug_output $stderr if ENV['POLOXY_DEBUG']
    end
    res = http.request post
    case res
    when Net::HTTPSuccess
      write_log "OK. #{res.code}"
    else
      write_log "Error! #{res.code}, #{res.message}, #{res.body}", :error
    end
    write_log "Sent #{message}", :debug
  end
end

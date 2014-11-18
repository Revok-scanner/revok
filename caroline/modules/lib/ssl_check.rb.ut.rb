require 'rexml/document'
require 'time'
module SSLCheck

    def init(url, cert_file)
      @uri = URI(url)
      @host = @uri.host
      @port = @uri.port
      @end_flag = false;
      @ssl_report = Hash.new()
      @cipherList = []

      get_ssl_socket(@host, @port, cert_file)
      @ssl_scan_file = `mktemp`.strip
      Log.info "Run sslscan..."
      `sslscan --no-failed --xml=#{@ssl_scan_file} #{@host}:#{@port}`
      Log.info "sslscan end"
      xmldata = File.read("#{@ssl_scan_file}")
      xmldata = xmldata.gsub(/&/, '&amp;')

      @doc = REXML::Document.new(xmldata)
      if @doc == nil
        Log.warn "REXML load sslscan xmlfile fail"
        @end_flag = ture
      else
        if @doc.root != nil
          @doc.root.each_element('//ssltest/cipher') do |item|
            @cipherList.push(item)
          end
        else
          Log.warn "scanssl failed"
          @end_flag = true;
        end
      end
    end

    def get_ssl_socket(host, port, trusted_cert_file)
      tcp_client = TCPSocket.new(host, port)
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      ssl_context.ca_file = trusted_cert_file
      Log.info "Connect with CA certificate file: #{ssl_context.ca_file}"

      begin
        ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
        ssl_client = ssl_client.connect
      rescue => exp
        if exp.class.name == "OpenSSL::SSL::SSLError"
          reason = "The site's security certificate is not trusted."
          advice = "Use a trusted certificate for your site."
          @ssl_report[:issuer_check] = [reason,advice]
        end
      end
      tcp_client.close if tcp_client != nil
      ssl_client.close if ssl_client != nil
    end

    def run_check
      @end_flag || sslv2_check
      @end_flag || nullCipher_check
      @end_flag || weakCipher_check
      @end_flag || md5SignedCert_check
      @end_flag || date_check
      @end_flag || ssl_forcing_check
      return @ssl_report
    end
	
    def sslv2_check
      Log.info "sslv2 check"
      if @cipherList.any?{ |item| item.attribute('sslversion') == 'SSLv2'}
        reason = "SSLv2 protocol is supported."
        advice = "Use SSLv3 or TLSv1 protocol."
        @ssl_report[:sslv2_check] = [reason,advice]
      end
    end

    def nullCipher_check
      Log.info "nullCipher check"
      if @cipherList.any?{ |item| item.attributes['bits'] == '0'}
        reason = "Null cipher is supported."
        advice = "Use strong ciphers."
        attach = @cipherList.find_all{|x| x.attributes['bits'] == '0'}.map{|y| "#{y.attributes['sslversion']} #{y.attributes['bits']}bits #{y.attributes['cipher']}"}
        @ssl_report[:nullCipher_check] = [reason, advice, attach]
      end
    end

    def weakCipher_check
      Log.info "weakCipher check"
      if @cipherList.any?{ |item| item.attributes['bits'].to_i < 112 and item.attributes['bits'].to_i > 0}
        reason = "Weak ciphers(key length < 112bits) are found."
        advice = "Use strong ciphers."
        attach = @cipherList.find_all{|x| x.attributes['bits'].to_i < 112 and x.attributes['bits'].to_i > 0 }.map{|y| "#{y.attributes['sslversion']} #{y.attributes['bits']}bits #{y.attributes['cipher']}"}
        @ssl_report[:weakCipher_check] = [reason, advice, attach]
      end
    end

    def md5SignedCert_check
      Log.info "md5SignedCert check"
      @doc.root.each_element('//ssltest/certificate/signature-algorithm') do |item|
        if item.get_text.value =~ /[Mm][Dd]5/
          reason = "Md5 signature algorithm is used."
          advice = "Use advanced signature algorithm for the certificate."
          @ssl_report[:md5SignedCert_check] = [reason, advice]
        end
      end
    end

    def date_check
      status = 0
      reason = ""
      attache = nil
      Log.info "date check"
      @doc.root.each_element('//ssltest/certificate/not-valid-before') do |item|
        if Time.parse(item.get_text.value) > Time.now
          reason = "The certificate is invalid."
          status = 1
          attache = ["Not valid before: #{item.get_text.value} (Now: #{Time.now})"]
        end
      end
      @doc.root.each_element('//ssltest/certificate/not-valid-after') do |item| 
        if Time.parse(item.get_text.value) < Time.now
          reason = "The certificate is out of date."
          status = 1
          attache = ["Not valid after: #{item.get_text.value} (Now: #{Time.now})"]
        end
      end
      if status == 1
        advice = "Set appropriate term of validity for the certificate."
        @ssl_report[:date_check] = [reason, advice, attache]
      end
    end
 
    def ssl_forcing_check
      Log.info "Strict-Transport-Security check"
      resp = `(echo -e \"GET #{@uri} HTTP/1.1\nHost: #{@host}\n\n\";sleep 10)|openssl s_client -connect #{@host}:#{@port} 2>/dev/null`
      if not resp.upcase.include?("STRICT-TRANSPORT-SECURITY")
        reason = "Strict-Transport-Security is not set."
        advice = "Add Strict-Transport-Security header."
        @ssl_report[:ssl_forcing_check] = [reason, advice]
      end
    end

    def finalize
      if @ssl_scan_file and File.exist?(@ssl_scan_file)
        File.delete(@ssl_scan_file)
      end
    end
end

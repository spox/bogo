require 'resolv'
require 'http'
require 'http/request'

# NOTE: This is a simple monkey patch to the httprb library to provide
# implicit proxy support to requests. It is defined within this
# library to allow easy sharing. It is the responsibility of the user
# to ensure the http gem is available!
class HTTP::Request

  # Override to implicitly apply proxy as required
  #
  # NOTE: If dealing with https request, force port so CONNECT request
  # will properly include destination port
  def proxy
    if((@proxy.nil? || @proxy.empty?) && ENV["#{uri.scheme}_proxy"] && proxy_is_allowed?)
      _proxy = URI.parse(ENV["#{uri.scheme}_proxy"])
      Hash.new.tap do |opts|
        opts[:proxy_address] = _proxy.host
        opts[:proxy_port] = _proxy.port
        opts[:proxy_username] = _proxy.user if _proxy.user
        opts[:proxy_password] = _proxy.password if _proxy.password
      end
    else
      @proxy if proxy_is_allowed?
    end
  end

  # Check `ENV['no_proxy']` and disable proxy if endpoint is listed
  #
  # @return [TrueClass, FalseClass]
  def proxy_is_allowed?
    if(ENV['no_proxy'])
      ENV['no_proxy'].to_s.split(',').map(&:strip).none? do |item|
        File.fnmatch(item, [uri.host, uri.port].compact.join(':'))
      end
    else
      true
    end
  end

  # Compute HTTP request header SSL proxy connection
  #
  # NOTE: Provide override to get port included within request
  def proxy_connect_header
    if(@uri.port.nil?)
      if(@uri.scheme == 'https')
        dest_port = 443
      else
        dest_port = 80
      end
    else
      dest_port = @uri.port
    end
    "CONNECT #{@uri.host}:#{dest_port} HTTP/#{version}"
  end

end

require 'resolv'
require 'http'
require 'http/request'

# NOTE: This is a simple monkey patch to the httprb library to provide
# implicit proxy support to requests. It is defined within this
# library to allow easy sharing. It is the responsibility of the user
# to ensure the http gem is available!
class HTTP::Request

  # Override to implicitly apply proxy as required
  def proxy
    if(@proxy.nil? &&_proxy_point = ENV["#{uri.scheme}_proxy"] && proxy_is_allowed?)
      _proxy = URI.parse(_proxy_point)
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
        File.fnmatch(uri.to_s, item)
      end
    else
      true
    end
  end

end

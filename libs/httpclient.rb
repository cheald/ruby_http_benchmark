require 'httpclient'

class HTTPClientBenchmark < BaseBenchmark
  COLOR = "#778899"
  def setup
    @client = HTTPClient.new
  end

  def run_sync(url)
    @client.get(url).content
  end

  ####################################

  def run_cookies(url)
    @client.get(url).content
  end

  ####################################

  def run_gzip(url)
    @client.get(url, headers: {"accept-encoding" => "gzip"}).content
  end
end

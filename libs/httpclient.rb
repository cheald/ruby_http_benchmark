require 'httpclient'

class HTTPClientBenchmark < BaseBenchmark
  COLOR = "#778899"
  def setup
    @client = HTTPClient.new
  end

  def run_warmup(url)
    @client.get(url).content
  end

  def run_sync(url)
    @client.get(url).content
  end

  ####################################

  def run_cookies(url)
    @client.get(url).content
  end

  ####################################

  def setup_gzip
    @client.transparent_gzip_decompression = true
  end

  def run_gzip(url)
    @client.get(url, headers: {"accept-encoding" => "gzip"}).content
  end

  def teardown_gzip
    @client.transparent_gzip_decompression = false
  end
end

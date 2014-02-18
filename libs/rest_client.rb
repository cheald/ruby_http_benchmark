require 'rest_client'
class RestClientBenchmark < BaseBenchmark
  COLOR = "#E9967A"
  def run_sync(url)
    RestClient.get(url).to_str
  end

  def run_gzip(url)
    RestClient.get(url, headers: {"accept_encoding" => "gzip, deflate"}).to_str
  end
end

require 'httparty'
class HTTPartyBenchmark < BaseBenchmark
  COLOR = "#556B2F"

  def run_warmup(url)
    HTTParty.get(url).body
  end

  def run_sync(url)
    HTTParty.get(url).body
  end

  def run_gzip(url)
    HTTParty.get(url, headers: {"accept-encoding" => "gzip"}).body
  end
end

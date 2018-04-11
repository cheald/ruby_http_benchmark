require 'curb'
class CurbBenchmark < BaseBenchmark
  COLOR = "#556B2F"

  def run_warmup(url)
    Curl.get(url).body_str
  end

  def run_sync(url)
    Curl.get(url).body_str
  end

  def run_gzip(url)
    Curl.get(url, {"accept-encoding" => "gzip"}).body_str
  end
end

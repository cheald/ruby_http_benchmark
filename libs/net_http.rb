require 'net/http'
class NetHttpBenchmark < BaseBenchmark
  COLOR = "#556B2F"

  def run_warmup(url)
    uri = URI.parse url
    Net::HTTP.get(uri)
  end

  def run_sync(url)
    uri = URI.parse url
    Net::HTTP.get(uri)
  end

  def run_gzip(url)
    uri = URI.parse url
    req = Net::HTTP::Get.new(uri)
    req['accept-encoding'] = "gzip"

    res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req) }
    res.body
  end
end

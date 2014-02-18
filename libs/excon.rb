require 'excon'
class ExconBenchmark < BaseBenchmark
  COLOR = "#BB8B00"
  def setup
    @client = nil
    Excon.defaults[:middlewares] << Excon::Middleware::Decompress unless Excon.defaults[:middlewares].include? Excon::Middleware::Decompress
  end

  def run_sync(url)
    @client ||= Excon.new(url, :persistent => true)
    @client.get(url).body
  end

  ####################################

  def run_gzip(*urls)
    urls.each do |url|
      @client ||= Excon.new(url, :persistent => true)
      @client.get(url, headers: {"accept-encoding" => "gzip, deflate"}).body
    end
  end
end

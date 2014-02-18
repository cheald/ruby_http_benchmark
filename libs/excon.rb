require 'excon'
class ExconBenchmark < BaseBenchmark
  COLOR = "#BB8B00"
  def setup_warmup
    @client = nil
  end

  def run_warmup(url)
    @client ||= Excon.new(url, persistent: true)
    @client.get.body
  end

  ####################################

  def setup_sync
    @client = nil
  end

  def run_sync(url)
    @client ||= Excon.new(url, persistent: true)
    @client.get.body
  end

  ####################################

  def setup_gzip
    @client = nil
  end

  def run_gzip(*urls)
    urls.each do |url|
      @client ||= Excon.new(url, :persistent => true, middlewares: Excon.defaults[:middlewares] + Array(Excon::Middleware::Decompress))
      @client.get.body
    end
  end
end

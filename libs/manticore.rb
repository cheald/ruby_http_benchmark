require 'manticore'

class ManticoreBenchmark < BaseBenchmark
  def setup_warmup
    @client = Manticore::Client.new cookies: false, compression: true
  end

  def run_warmup(url)
    @client.get(url).body
  end

  COLOR = "#1E90FF"
  def setup_sync
    @client = Manticore::Client.new cookies: false, compression: false
  end

  def run_sync(url)
    @client.get(url).body
  end

  ####################################

  def setup_cookies
    @client = Manticore::Client.new cookies: true, compression: false
  end

  def run_cookies(url)
    @client.get(url).body
  end

  ####################################

  def setup_gzip
    @client = Manticore::Client.new compression: true
  end

  def run_gzip(*urls)
    urls.each do |url|
      @client.get(url).body
    end
  end

  ####################################

  def setup_async_plain
    @client = Manticore::Client.new compression: false, pool_max_per_route: 8
  end

  def run_async_plain(*urls)
    urls.each do |url|
      @client.async_get(url).on_success {|res, req| res.body }
    end
    @client.execute!
  end

  ####################################

  def setup_async_gzip
    @client = Manticore::Client.new compression: true, pool_max_per_route: 8
  end

  def run_async_gzip(*urls)
    urls.each do |url|
      @client.async_get(url).on_success {|res, req| res.body }
    end
    r = @client.execute!
  end

end
require 'typhoeus'
class TyphoeusBenchmark < BaseBenchmark
  COLOR = "#008B8B"
  def setup
    Typhoeus::Pool.clear
  end

  def run_warmup(url)
    Typhoeus.get(url, followlocation: true, accept_encoding: "gzip").body
  end

  def run_sync(url)
    Typhoeus.get(url, followlocation: true).body
  end

  ####################################

  def setup_cookies
    @cookies = Tempfile.new('typhoeus_cookies')
  end

  def run_cookies(url)
    Typhoeus.get(url, followlocation: true, cookiefile: @cookies, cookiejar: @cookies).body
  end

  ####################################

  def run_gzip(*urls)
    urls.each do |url|
      Typhoeus.get(url, followlocation: true, accept_encoding: "gzip").body
    end
  end

  def validate_gzip(url)
    r = Typhoeus.get(url, followlocation: true, accept_encoding: "gzip")
    assert r.headers["Content-Encoding"] == "gzip", "did not find content-encoding: gzip in response headers"
  end

  ####################################

  def run_async_plain(*urls)
    hydra = Typhoeus::Hydra.new
    urls.each do |url|
      request = Typhoeus::Request.new(url, followlocation: true)
      request.on_success {|response| response.body }
      hydra.queue request
    end
    hydra.run
  end

  def run_async_gzip(*urls)
    hydra = Typhoeus::Hydra.new
    urls.each do |url|
      request = Typhoeus::Request.new(url, followlocation: true, accept_encoding: "gzip")
      request.on_success {|response| response.body }
      hydra.queue request
    end
    hydra.run
  end
end

require 'benchmark'
require 'gnuplot'
require 'hitimes'

class UnsupportedFeatureException < Exception; end
class FailedValidationException < Exception; end

class BaseBenchmark
  def run_sync(url); end
  @children = []
  class << self
    attr_accessor :children
  end
  attr_reader :timings

  def self.inherited(other)
    @children << other
  end

  HOST = "localhost:8811"

  RUNS = {
    warmup: 5000,
    small: 500,
    medium: 500,
    large: 500,
    very_large: 100,
    x_large: 100
  }

  RUNSET_SIZES = {
    small: "1KB",
    medium: "10KB",
    large: "100KB",
    very_large: "1MB",
    x_large: "10MB",
  }

  TESTS = {
    warmup: {
      name: "%sx Synchronous Uncompressed - %s",
      runsets: {
        small:      Array.new(1, "http://#{HOST}/1k.bin"),
      }
    },
    sync: {
      name: "%sx Synchronous Uncompressed - %s",
      runsets: {
        small:      Array.new(1, "http://#{HOST}/1k.bin"),
        medium:     Array.new(1, "http://#{HOST}/10k.bin"),
        large:      Array.new(1, "http://#{HOST}/100k.bin"),
        very_large: Array.new(1, "http://#{HOST}/1000k.bin"),
        x_large:    Array.new(1, "http://#{HOST}/10000k.bin"),
      }
    },
    gzip: {
      name: "%sx Synchronous Gzipped - %s",
      runsets: {
        small:      Array.new(1, "http://#{HOST}/1k.bin"),
        medium:     Array.new(1, "http://#{HOST}/10k.bin"),
        large:      Array.new(1, "http://#{HOST}/100k.bin"),
        very_large: Array.new(1, "http://#{HOST}/1000k.bin"),
        x_large:    Array.new(1, "http://#{HOST}/10000k.bin"),
      }
    },

    async_plain: {
      name: "%sx Asynchronous Uncompressed - %s",
      runsets: {
        small:      Array.new(8, "http://#{HOST}/1k.bin"),
        medium:     Array.new(8, "http://#{HOST}/10k.bin"),
        large:      Array.new(8, "http://#{HOST}/100k.bin"),
        very_large: Array.new(8, "http://#{HOST}/1000k.bin"),
        x_large:    Array.new(8, "http://#{HOST}/10000k.bin"),
      }
    },

    async_gzip: {
      name: "%sx Asynchronous Gzipped - %s",
      runsets: {
        small:      Array.new(8, "http://#{HOST}/1k.bin"),
        medium:     Array.new(8, "http://#{HOST}/10k.bin"),
        large:      Array.new(8, "http://#{HOST}/100k.bin"),
        very_large: Array.new(8, "http://#{HOST}/1000k.bin"),
        x_large:    Array.new(8, "http://#{HOST}/10000k.bin"),
      }
    }
  }

  def self.prepare(test, runset, times, args)
    instance = new(test, runset)
    instance.setup if instance.respond_to? :setup
    instance.send "setup_#{test}" if instance.respond_to? "setup_#{test}"
    instance.send "validate_#{test}", *args if instance.respond_to? "validate_#{test}"
    instance.unsupported! unless instance.respond_to? "run_#{test}"
    blk = -> {
      times.times {|i|
        d = Hitimes::Interval.measure {
          instance.send "run_#{test}", *args.map.with_index {|v, x| v + "?#{i}-#{x}" }
        }
        instance.timings << d * 1000.0
      }
    }
    return blk, instance
  end

  def initialize(test, runset)
    @test = test
    @runset = runset
    @run = 1
    @timings = []
  end

  def clean_timings
    sorted = @timings.sort
    max = sorted[(@timings.length * 0.9).floor]
    @timings.select {|v| v <= max }
  end

  def next_run
    @run += 1
    @timings.clear
  end

  def graph_title
    "#{self.class.to_s} #{@test}/#{@runset} Pass ##{@run}"
  end

  def unsupported!
    raise UnsupportedFeatureException.new("test `#{@test}` is not supported")
  end

  def assert(assertion, message = nil)
    raise FailedValidationException.new("test `#{@test}` failed validation: #{message}") unless assertion
  end

  def teardown
    send "teardown_#{@test}" if respond_to? "teardown_#{@test}"
  end
end

libs = %w{
  curb
  excon
  httparty
  httpclient
  manticore
  net_http
  rest_client
  typhoeus
}.each do |lib|
  begin
    require_relative "./libs/#{lib}"
  rescue LoadError
    puts "Skipping #{lib} - failed to load"
  end
end

shuffled = BaseBenchmark.children.shuffle
BaseBenchmark::TESTS.each do |test, options|
  options[:runsets].each do |runset, args|
    filename = "#{Time.now.to_i}-#{test}-#{runset}"
    # Gnuplot.open do |gp|
    File.open( "out/#{filename}.gnuplot", "w") do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.ylabel "ms"
        plot.xlabel "Framework"
        plot.data = []
        plot.grid "ytics lc rgb \"#bbbbbb\" lw 1 lt 0"
        plot.grid "xtics lc rgb \"#bbbbbb\" lw 1 lt 0"
        plot.style "fill solid 0.25 border -1"

        plot.style 'boxplot pointtype 7'
        plot.style 'data boxplot'
        plot.boxwidth ' 0.5'
        plot.pointsize '0.5'
        plot.xtics 'nomirror'
        plot.ytics 'nomirror'
        plot.border '2'
        plot.title options[:name] % [BaseBenchmark::RUNS[runset], BaseBenchmark::RUNSET_SIZES[runset]]

        x_classes = []
        Benchmark.bm do |x|
          actual_index = 1
          shuffled.each.with_index do |klass, index|
            begin
              idx = x_classes.length + 1
              shortname = klass.to_s.gsub(/Benchmark$/, "")
              block, instance = klass.prepare(test, runset, BaseBenchmark::RUNS[runset], args)
              x.report "%s: %s (%s)" % [shortname, test, runset], &block
              plot.style "line #{idx} lc rgb \"#{klass::COLOR}\" lw 1"
              plot.data << Gnuplot::DataSet.new(instance.clean_timings) do |ds|
                ds.title = shortname
                ds.using = "(#{idx}):1 ls #{idx}"
              end
              x_classes << shortname
              instance.teardown
              instance.next_run
            rescue UnsupportedFeatureException, FailedValidationException => e
              puts "#{klass.to_s}: #{e.message}"
            end
          end
        end

        plot.xtics "(%s) scale 0.0" % x_classes.map.with_index {|c, i| "\"#{c}\" #{i+1}" }.join(", ")
      end
    end
  end
end

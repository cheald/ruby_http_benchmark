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

  RUNS = {
    small: 500,
    medium: 500,
    large: 500,
    very_large: 100,
    x_large: 100
  }

  TESTS = {
    sync: {
      runsets: {
        small:      Array.new(1, "http://localhost/benchmark/1k.txt"),
        medium:     Array.new(1, "http://localhost/benchmark/10k.txt"),
        large:      Array.new(1, "http://localhost/benchmark/100k.txt"),
        very_large: Array.new(1, "http://localhost/benchmark/1000k.txt"),
        x_large:    Array.new(1, "http://localhost/benchmark/10000k.txt"),
      }
    },
    gzip: {
      runsets: {
        small:      Array.new(1, "http://localhost/benchmark/1k.txt"),
        medium:     Array.new(1, "http://localhost/benchmark/10k.txt"),
        large:      Array.new(1, "http://localhost/benchmark/100k.txt"),
        very_large: Array.new(1, "http://localhost/benchmark/1000k.txt"),
        x_large:    Array.new(1, "http://localhost/benchmark/10000k.txt"),
      }
    },

    async_plain: {
      runsets: {
        small:      Array.new(8, "http://localhost/benchmark/1k.txt"),
        medium:     Array.new(8, "http://localhost/benchmark/10k.txt"),
        large:      Array.new(8, "http://localhost/benchmark/100k.txt"),
        very_large: Array.new(8, "http://localhost/benchmark/1000k.txt"),
        x_large:    Array.new(8, "http://localhost/benchmark/10000k.txt"),
      }
    },

    async_gzip: {
      runsets: {
        small:      Array.new(8, "http://localhost/benchmark/1k.txt"),
        medium:     Array.new(8, "http://localhost/benchmark/10k.txt"),
        large:      Array.new(8, "http://localhost/benchmark/100k.txt"),
        very_large: Array.new(8, "http://localhost/benchmark/1000k.txt"),
        x_large:    Array.new(8, "http://localhost/benchmark/10000k.txt"),
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

require_relative "./libs/httparty.rb"
require_relative "./libs/httpclient.rb"
require_relative "./libs/typhoeus.rb"
require_relative "./libs/manticore.rb"
require_relative "./libs/rest_client.rb"

shuffled = BaseBenchmark.children.shuffle
BaseBenchmark::TESTS.each do |test, options|
  options[:runsets].each do |runset, args|
    filename = "#{Time.now.to_i}-#{test}-#{runset}"
    # Gnuplot.open do |gp|
    File.open( "out/#{filename}.gnuplot", "w") do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.ylabel "ms"
        plot.xlabel "request"
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

        x_classes = []
        Benchmark.bm do |x|
          shuffled.each.with_index do |klass, index|
            begin
              shortname = klass.to_s.gsub(/Benchmark$/, "")
              block, instance = klass.prepare(test, runset, BaseBenchmark::RUNS[runset], args)
              x.report "%s: %s (%s)" % [shortname, test, runset], &block
              plot.style "line #{index+1} lc rgb \"#{klass::COLOR}\" lw 2 pt 3"
              plot.data << Gnuplot::DataSet.new(instance.clean_timings) do |ds|
                ds.title = shortname
                ds.using = "(#{index+1}):1 ls #{index + 1}"
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

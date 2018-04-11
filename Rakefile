require 'tempfile'

task :default => [:build, :start_docker, :clean, :run, :stop_docker, :plot]

task :clean do
  sh "rm -f out/*.gnuplot"
end

task :run do
  sh "ruby benchmark.rb"
end

task :plot do
  sh "rm -rf plots"
  sh "mkdir -p plots"
  p Dir["out/**/*.gnuplot"]
  Dir["out/**/*.gnuplot"].each do |file|
    puts "plot #{file}"
    name = File.basename(file).split(".").first
    cmd = <<-EOF
      set terminal pngcairo size 640,480 enhanced
      set output '#{File.expand_path File.join("plots", "#{name}.png")}'
      #{File.read file}
    EOF

    f = Tempfile.open("gnuplot")
    begin
      f.puts cmd
      f.close
      sh "gnuplot #{f.path}"
    ensure
      f.unlink
    end
  end
end

task :build do
  sh "docker build . -t ruby-http-benchmark:latest"
end

task :start_docker do
  sh "docker run --name ruby-http-benchmark-server -d -p 8811:80 ruby-http-benchmark:latest"
end

task :stop_docker do
  sh "docker rm -f ruby-http-benchmark-server"
end
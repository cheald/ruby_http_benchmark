task :default do
  sh "ruby benchmark.rb"
end

require 'tempfile'

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
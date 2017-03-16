
task :build do
  Rake::Task[:compile].invoke 'rite'
  Rake::Task[:compile].reenable
  Rake::Task[:compile].invoke 'ritual'
end

task :compile, [:path] do |t, args|
  Dir.chdir args[:path] do
    system 'nimble', 'build', '--debug'
  end
end

task :generate do
  puts 'generating content...'
end

task :serve => [:build, :generate] do
  # spawn ritual as a daemonized process here
  system 'ngnix', '-c', './nginx/config'
end

task :stop do
  system 'killall', 'nginx'
  system 'killall', 'ritual'
end

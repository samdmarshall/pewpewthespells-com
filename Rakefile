task :default => :build

task :compile, [:path] do |t, args|
  Dir.chdir args[:path] do
    system 'nimble', 'build', '--debug'
  end
end

task :build do
  Rake::Task[:compile].invoke 'rite'
  Rake::Task[:compile].reenable
  Rake::Task[:compile].invoke 'ritual'
end

task :serve => [:build] do
  
end


task :stop do
  system 'killall', 'nginx'
  system 'killall', 'ritual'
end

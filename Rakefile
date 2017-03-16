def compile(path)
  Dir.chdir path do
    system 'nimble', 'build', '--debug'
  end
end

task :default => :help

task :help do
  puts 'usage: rake [build|generate|serve|stop|clean]'
end

task :build do
  compile 'rite'
  compile 'ritual'
end

task :generate do
  if not FileUtils.exists? 'rite/rite'
    Rake::Task[:build].invoke
  end
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

task :clean do
  FileUtils.rm('ritual/ritual')
  FileUtils.remove_dir('ritual/nimcache/')

  FileUtils.rm('rite/rite')
  FileUtils.remove_dir('rite/nimcache/')
  
  FileUtils.remove_dir('content/public/')
end

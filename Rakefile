require 'rbconfig'

def runningOS
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    else
      raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
    end
  )
end

task :build do
  ["rite", "ritual"].each do |action|
    Dir.chdir(action) do
      system "nimble", "build", "--debug"
    end
  end
end

task :serve => [:build] do
  
end


task :stop do
  system "killall", "nginx"
  system "killall", "ritual"
end

$ROOT_PATH=ENV['ROOT_PATH']
$: << "#{$ROOT_PATH}/model/"

require 'model.Server.RunCase'

$CAROLINE_PATH="#{$ROOT_PATH}/caroline"
active = true

def update
  fresh=true
  Dir.chdir($ROOT_PATH) do
    system '/usr/bin/git submodule init 2>/dev/null'
    fresh = system '([ `/usr/bin/git submodule update 2>/dev/null | wc -l` -le 1 ] && [ `/usr/bin/git pull 2>/dev/null| wc -l` -le 1 ])'     
  end
  return (not fresh)
end

def clean_exit
  puts "Goodbye, Caroline!"
  if $runCaseServer
    $runCaseServer.clean 
    $runCaseServer=nil
  end
  exit(0)
end

$runCaseServer=RunCaseServer.new

trap("SIGINT") do
  if active 
    puts "\nSir! We're still doing science. Give me a few seconds to clean up."
    active = false
  else 
    if $runCaseServer
      $runCaseServer.clean 
      $runCaseServer=nil
    end
    raise SystemExit
  end
end

to_run = []
begin
  while active do
    
    next unless active

    begin
      puts "Checking for test scans to be run..."
      runCase=$runCaseServer.getRunCaseFromQueue
      if runCase
        if runCase.scanConfigObj.screenshot==0
          clean_exit if update
        end
        $runCaseServer.ackRunCaseToQueue
        result=$runCaseServer.validate(runCase)
        to_run << runCase if result
      end
    end

    to_run.each do |run| 
      puts "Running scan #{run.id}..."
      Dir.chdir($CAROLINE_PATH) do 
        break unless active
        $runCaseServer.run(run)
        $runCaseServer.saveRunCaseToDB(run,true)
        to_run.delete(run)
      end
    end
  end
rescue => exp
  puts $!
  $stderr.puts "#{exp.backtrace.join("\n")}"
end

clean_exit

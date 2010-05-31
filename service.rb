# service.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

module Service
  class Service
    attr_reader :name

    def initialize(name, script, args = [])
      @name = name
      @script = script
      @args = args

      @stdout = nil
      @stderr = nil
      
      @task = nil
    end
    
    def to_s
      @name
    end
    
    def started
      @task && @task.isRunning
    end

    def start(queue, view_writer)
      if not started
        @started = true
        @stdout = NSPipe.pipe
        @stderr = NSPipe.pipe

        @task = NSTask.new
        stdout_file = IO.new(@stdout.fileHandleForReading.fileDescriptor, 'r')
        stderr_file = IO.new(@stderr.fileHandleForReading.fileDescriptor, 'r')

        @task.setStandardOutput @stdout
        @task.setStandardError @stderr
        @task.setLaunchPath @script
        @task.setArguments @args

        Dispatch::Source.read(stdout_file, queue) do |s|
          if s.data > 0
            output = stdout_file.read s.data
            NSLog("Got stdout: #{output}")
            view_writer.write output
            sleep 0.25
          end
        end

        Dispatch::Source.read(stderr_file, queue) do |s|
          if s.data > 0
            output = stderr_file.read s.data
            NSLog("Got stderr: #{output}")

            view_writer.write output
            sleep 0.25
          end
        end

        Dispatch::Job.new do
          @task.launch
          @task.waitUntilExit
          @started = false
        end
      end
    end
    
    def stop
      if started
        @task.terminate
      end
    end
  end

  class ServiceManager
    def initialize()
      @services = []
    end
    
    # data source methods
    def numberOfRowsInTableView(view)
      @services.size
    end

    def tableView(view, objectValueForTableColumn:column, row:index)
      @services[index].to_s
    end
    
    # action methods
    
    def add(service)
      @services << service
    end
    
    def delete(service)
      @services.delete service
    end
    
    def selected_service(view)
      row_index = view.selectedRow
      
      if row_index > -1 then
        @services[row_index]
      else
        nil
      end
    end
    
    def stop
      @services.each do |service|
        NSLog("Stopping #{service.name}")
        service.stop
      end
    end
  end

end
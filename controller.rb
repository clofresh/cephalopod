# controller.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

framework 'Cocoa'
require 'dispatch'

class Service
  attr_reader :started

  def initialize(name, script, args = [])
    @name = name
    @script = script
    @args = args

    @stdout = nil
    @stderr = nil
    
    @started = false
  end
  
  def to_s
    @name
  end

  def start(queue, view_writer)
    if not @started
      @started = true
      @stdout = NSPipe.pipe
      @stderr = NSPipe.pipe

      task = NSTask.new
      stdout_file = IO.new(@stdout.fileHandleForReading.fileDescriptor, 'r')
      stderr_file = IO.new(@stderr.fileHandleForReading.fileDescriptor, 'r')

      task.setStandardOutput @stdout
      task.setStandardError @stderr
      task.setLaunchPath @script
      task.setArguments @args

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
        task.launch
        task.waitUntilExit
        @started = false
      end
    end
  end
end

class ViewWriter
  def initialize(view)
    @view = view
  end

  def write(text)
    endRange = NSRange.new
    endRange.location = @view.textStorage.length
    endRange.length = 0
    @view.replaceCharactersInRange(endRange, withString:text)
    endRange.length = output.length
    @view.scrollRangeToVisible(endRange)
  end
  
end

class Cephalopod
  attr_writer :servicesView, :logOutputView
  
  def awakeFromNib
    @queue = Dispatch::Queue.new 'com.cephalopodapp.services'
    @incoming_text_queue = Dispatch::Queue.new 'com.cephalopodapp.incoming'
    @services = []
    @servicesView.dataSource = self
    @view_writer = Dispatch::Job.new().synchronize(ViewWriter.new(@logOutputView))
  end
  
  def appendText(text)
    @view_writer.write text
  end
  
  # servicesView protocol implementation
  
  def numberOfRowsInTableView(view)
    @services.size
  end

  def tableView(view, objectValueForTableColumn:column, row:index)
    @services[index].to_s
  end  
  
  # Actions
  
  def addService(sender)
    NSLog('add service')
    service = Service.new 'Test service', '/usr/local/bin/memcached', ['-p22122', '-vv']
    @services << service
    @servicesView.reloadData
  end

  def deleteService(sender)
    row_index = @servicesView.selectedRow
    
    if row_index > -1 then
      NSLog('delete service')
      @services.delete_at row_index
      @servicesView.reloadData
    end
  end

  def startService(sender)
    row_index = @servicesView.selectedRow
    
    if row_index > -1 or true then
      NSLog('start service')

      @services[row_index].start @queue, @view_writer
    end
  end

  def stopService(sender)
    NSLog('stop service')
  end

  def restartService(sender)
    NSLog('restart service')
  end
end

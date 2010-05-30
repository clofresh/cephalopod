# controller.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

framework 'Cocoa'
require 'dispatch'

class Service
  def initialize(name, script)
    @name = name
    @script = script
  end
  
  def to_s
    @name
  end
end

class Cephalopod
  attr_writer :servicesView, :logOutputView
  
  def awakeFromNib
    @queue = Dispatch::Queue.new 'com.cephalopodapp.services'
    @services = []
    @servicesView.dataSource = self
  end
  
  def appendText(text)
    endRange = NSRange.new
    endRange.location = @logOutputView.textStorage.length
    endRange.length = 0
    @logOutputView.replaceCharactersInRange(endRange, withString:text)
    endRange.length = output.length
    @logOutputView.scrollRangeToVisible(endRange)
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
    service = Service.new 'Test service', 'tail -f /var/log/system.log'
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

      stdout = NSPipe.pipe
      stderr = NSPipe.pipe

      task = NSTask.new
      stdout_file = IO.new(stdout.fileHandleForReading.fileDescriptor, 'r')
      stderr_file = IO.new(stderr.fileHandleForReading.fileDescriptor, 'r')

      task.setStandardOutput stdout
      task.setStandardError stderr
      task.setLaunchPath '/usr/local/bin/memcached'
      task.setArguments ['-vvv', '-p 22122']

      Dispatch::Source.read(stdout_file, @queue) do |s|
        if s.data > 0
          output = stdout_file.read s.data
          NSLog("Got stdout: #{output}")
          appendText output
        end
      end

      Dispatch::Source.read(stderr_file, @queue) do |s|
        if s.data > 0
          output = stderr_file.read s.data
          NSLog("Got stderr: #{output}")

          appendText output
        end
      end

      Dispatch::Job.new do
        task.launch
      end

    end
  end

  def stopService(sender)
    NSLog('stop service')
  end

  def restartService(sender)
    NSLog('restart service')
  end
end

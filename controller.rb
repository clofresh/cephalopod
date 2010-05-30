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
      file = File.open('/tmp/input.log')
      
      Dispatch::Source.read(file, @queue) do |s|
        data = file.read(s.data)
        
        endRange = NSRange.new
        endRange.location = @logOutputView.textStorage.length
        endRange.length = 0
        @logOutputView.replaceCharactersInRange(endRange, withString:data)
        endRange.length = data.length
        @logOutputView.scrollRangeToVisible(endRange)
        NSLog("Got data: #{data}")
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

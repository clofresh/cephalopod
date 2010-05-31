# controller.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

framework 'Cocoa'
require 'dispatch'
require 'service'
include Service

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
    
    NSNotificationCenter.defaultCenter.addObserver(self, 
      selector: :application_will_terminate, 
      name: NSApplicationWillTerminateNotification, 
      object:nil
    )
    
  end
  
  def application_will_terminate
    @services.each do |service|
      NSLog("Stopping #{service.name}")
      service.stop
    end
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

  def toggleService(sender)
    row_index = @servicesView.selectedRow
    
    if row_index > -1 or true then
      service = @services[row_index]
      
      if service.started
        NSLog('stop service')
        service.stop
      else
        NSLog('start service')
        service.start @queue, @view_writer
      end
    end
  end
  
  def restartService(sender)
    NSLog('restart service')
  end
end

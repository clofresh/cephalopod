# controller.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

framework 'Cocoa'
require 'dispatch'
require 'service'

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
    @service_manager = Service::ServiceManager.new
    @servicesView.dataSource = @service_manager
    @view_writer = Dispatch::Job.new().synchronize(ViewWriter.new(@logOutputView))
    
    NSNotificationCenter.defaultCenter.addObserver(self, 
      selector: :application_will_terminate, 
      name: NSApplicationWillTerminateNotification, 
      object:nil
    )
    
  end
  
  def application_will_terminate
    @service_manager.stop
  end
  
  def appendText(text)
    @view_writer.write text
  end
  
  # Actions
  
  def addService(sender)
    service = Service::Service.new 'Test service', '/usr/local/bin/memcached', ['-p22122', '-vv']
    @service_manager.add service
    @servicesView.reloadData
  end

  def deleteService(sender)
    to_delete = @service_manager.selected_service @servicesView
    @service_manager.delete to_delete
    @servicesView.reloadData
  end

  def toggleService(sender)
    service = @service_manager.selected_service @servicesView
    
    if service then
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

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
  attr_writer :servicesView, :logOutputView, :addServicePanel, :newServiceName, :newServiceScript
  
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
    NSApplication.sharedApplication.runModalForWindow @addServicePanel
  end
  
  def saveNewService(sender)
    service_name = @newServiceName.stringValue
    service_script = @newServiceScript.stringValue
    service_args = []
    
    service = Service::Service.new service_name, service_script, service_args
    @service_manager.add service
    @servicesView.reloadData
    @addServicePanel.orderOut nil
    NSApplication.sharedApplication.stopModal

    @newServiceName.setStringValue ''
    @newServiceScript.setStringValue ''
  end

  def cancelNewService(sender)
    @addServicePanel.orderOut nil
    NSApplication.sharedApplication.stopModal

    @newServiceName.setStringValue ''
    @newServiceScript.setStringValue ''
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

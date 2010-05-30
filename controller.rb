# controller.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

class Service
  def initialize(name)
    @name = name
  end
  
  def to_s
    @name
  end
end

class Cephalopod
  attr_writer :servicesView, :logOutputView
  
  def awakeFromNib
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
    service = Service.new 'Test service'
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
    NSLog('start service')
  end

  def stopService(sender)
    NSLog('stop service')
  end

  def restartService(sender)
    NSLog('restart service')
  end
end

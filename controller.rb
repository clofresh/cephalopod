# controller.rb
# Cephalopod
#
# Created by Carlo Cabanilla on 5/30/10.
# Copyright 2010 Carlo Cabanilla. All rights reserved.

class Cephalopod
  attr_writer :servicesView, :logOutputView
  
  def addService(sender)
    NSLog('add service')
  end

  def deleteService(sender)
    NSLog('delete service')
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

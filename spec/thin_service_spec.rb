require 'spec_helper'

describe ThinService do
  it 'should print version' do
    ThinService::Service.new( ["--version"]).run!
  end
  it 'should print help' do
    ThinService::Service.new( ["--help"]).run!
  end
  it 'should print help too' do
    ThinService::Service.new( ["-h"]).run!
  end
  it 'should fail to remove due to missing name' do
    ThinService::Service.new( ["remove"]).run!
  end
  it 'should print remove help' do
    ThinService::Service.new( ["remove", "-h"]).run!
  end
  it 'should print remove help too' do
    ThinService::Service.new( ["remove", "--help"]).run!
  end
  it 'should fail to install due to missing name' do
    ThinService::Service.new( ["install"]).run!
  end
  it 'should print install help' do
    ThinService::Service.new( ["install", "-h"]).run!
  end
  it 'should print install help too' do
    ThinService::Service.new( ["install", "--help"]).run!
  end
  it 'should fail to install due to no rails app' do
    ThinService::Service.new( ["install", "-N", "test_thin_service"]).run!
  end
  it 'should fail to install due to ' do
    ThinService::Service.new( ["install", "-N", "test_thin_service", "-c", "C:/Users/Owner/Documents/NetBeansProjects/hgcs"]).run!
  end
  it 'should fail to remove due to no rails app' do
    ThinService::Service.new( ["remove", "-N", "test_thin_service"]).run!
  end

  

end
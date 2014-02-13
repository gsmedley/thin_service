# ThinService

Run Thin or any rake task as a Windows Service - based on mongrel_service by Luis Lavena

## Installation

Add this line to your application's Gemfile:

    gem 'thin_service'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install thin_service

## Usage

Use the following commands to get more help:

    thin_service install --help
    thin_service remove --help


To install a rake task, such as a background processor, as a service:

    thin_service installdaemon -N service_name -t"rake my_background_task RAILS_ENV=production"  -c"full path to my rails app" 
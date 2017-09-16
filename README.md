# Castle::Middleware [![Build Status](https://travis-ci.org/brissmyr/castle-ruby-middleware.svg?branch=master)](https://travis-ci.org/brissmyr/castle-ruby-middleware)

## Installation

Add this line to your Rack application's Gemfile:

```ruby
gem 'castle-middleware'
```

And set your Castle credentials in an initializer:

```ruby
Castle::Middleware.configure do |config|
  config.app_id = '186593875646714'
  config.api_secret = 'abcdefg123456789'
end
```

The middleware will insert itself into the Rack middleware stack.

## Usage

The middleware will insert Castle.js into the HEAD tag on all your pages, as well as log track any POST, PUT and DELETE requests as Castle events.

### Identifying the logged in user

Call `identify` on the `env['castle']` object to register the currently logged in user. This call will not issue an API request, but instead piggyback the information on the next server-side event.

```ruby
class ApplicationController < ActionController::Base
  before_action do
    if current_user
      env['castle'].identify(current_user.id, {
        created_at: current_user.created_at,
        email: current_user.email,
        name: current_user.name
      })
    end
  end

  # ...
end
```

## Configuration

### Manually inserting middleware in Rails

```ruby
Castle::Middleware.configure do |config|
  config.auto_insert_middleware = false
end
```

```ruby
# config/application.rb
app.config.middleware.insert_after ActionDispatch::Flash, # Replace this if needed
                                   Castle::Middleware::Tracking
app.config.middleware.insert_after ActionDispatch::Flash, # Replace this if needed
                                   Castle::Middleware::Sensor
```


### Async tracking

By default Castle sends tracking requests synchronously. To eg. use Sidekiq
to send requests in a background worker you can override the transport method

```ruby
# castle_worker.rb

class CastleWorker
  include Sidekiq::Worker

  def perform(params, context)
    ::Castle::Middleware.track(params, context)
  end
end

# initializers/castle.rb

Castle::Middleware.configure do |config|
  config.transport = lambda do |params, context|
    CastleWorker.perform_async(params, context)
  end
end

```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


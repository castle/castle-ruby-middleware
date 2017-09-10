# Castle::Middleware

## Installation

Add this line to your Rack application's Gemfile:

```ruby
gem 'castle-middleware'
```

And set your Castle credentials in an initializer:

```ruby
Castle::Middleware.app_id = '186593875646714'
Castle::Middleware.api_secret = 'O2ygKmdFTWSqhAF1SL1UyttyEiHCz9F'
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

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


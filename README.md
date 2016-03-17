# Featureswitches

A Ruby gem for interacting with [FeatureSwitches.com](https://featureswitches.com).  This library is under active development and is likely to change frequently.  Bug reports and pull requests are welcome.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'featureswitches'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install featureswitches

## Usage

```ruby
fs = FeatureSwitches.new('customer_api_key', 'environment_api_key', {options})

# Ensure that the API credentials are valid
result = fs.authenticate  # result will be true/false to indicate success

# Add a user
result = fs.add_user('user_identifier', 'optional_customer_identifier', 'optional_name', 'optional_email')

# Check if a feature is enabled
result = fs.is_enabled('feature_key', 'optional_user_identifier', default_return_value(true/false, default=false))

if result
    # Feature enabled, do something
else
    # Feature disabled, do something else
end
```

### Configuration Options
A few options are available to be tweaked if you so choose. The library makes use of a local cache to minimize requests back to the FeatureSwitches server. Additionally, a check it performed at an interval to automatically re-sync feature state when changes are made in the dashboard.

```ruby
{
    :cache_timeout => SECONDS, # optional, defaults to 300 seconds
    :check_interval => SECONDS # optional, defaults to 10 seconds
}
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/featureswitches/featureswitches-ruby.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


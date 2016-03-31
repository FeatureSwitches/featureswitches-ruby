require "featureswitches/version"
require "thread"
require "cache"
require "nestful"

class Featureswitches
    def initialize(customer_key, environment_key, options={})
        @customer_key = customer_key
        @environment_key = environment_key
        @cache_timeout = options[:cache_timeout] ||= 300
        @check_interval = options[:check_interval] ||= 10
        @last_update = 0
        @last_dirty_check = 0
        @api = options[:api] ||= 'https://api.featureswitches.com/v1/'

        @cache = Cache.new

        if @cache_timeout > 0
            @dirty_check_thread = do_dirty_check
        end
    end

    def authenticate
        endpoint = 'authenticate'
        response = api_request(endpoint)

        return response
    end

    def sync
        endpoint = 'features'

        if @cache_timeout > 0
            response = api_request(endpoint)

            features = response[:data]['features']

            features.each do |feature|
                feature['last_sync'] = Time.now.to_i
                @cache[feature['feature_key']] = feature
            end
        end
    end

    def is_enabled(feature_key, user_identifier=nil, default=false)
        feature = @cache[feature_key]
        if not feature or cache_is_stale(feature)
            feature = get_feature(feature_key)
        end

        if feature
            result = enabled_for_user(feature, user_identifier)

            if not result and feature['enabled'] == true and feature['rollout_progress'] < feature['rollout_target']
                enabled = get_feature_enabled(feature_key, user_identifier)

                if enabled == true and @cache_timeout > 0
                    feature['include_users'].push(user_identifier)
                    @cache[feature['feature_key']] = feature
                end

                return enabled
            end

            return result
        end

        return default
    end

    def add_user(user_identifier, customer_identifier=nil, name=nil, email=nil)
        endpoint = 'user/add'
        params = {
            'user_identifier' => user_identifier,
            'customer_identifier' => customer_identifier,
            'name' => name,
            'email' => email
        }
        response = api_request(endpoint, params, :post)

        if response[:success]
            return true
        end
        return false
    end

    def dirty_check
        endpoint = 'dirty-check'
        response = api_request(endpoint)
        
        if response[:success]
            @last_dirty_check = Time.now.to_i

            if response[:data]['last_update'] > @last_update
                @last_update = response[:data]['last_update']
                sync()
            end
        end
    end

    private

    def get_feature(feature_key)
        endpoint = 'feature'
        params = {'feature_key' => feature_key}
        response = api_request(endpoint, params)

        if response[:success]
            feature = response[:data]['feature']

            feature['last_sync'] = Time.now.to_i
            if @cache_timeout > 0
                @cache[feature['feature_key']] = feature
            end

            return feature
        end

        return nil
    end

    def get_feature_enabled(feature_key, user_identifier)
        endpoint = 'feature/enabled'
        params = {
            'feature_key' => feature_key,
            'user_identifier' => user_identifier
        }

        response = api_request(endpoint, params)

        if response[:success]
            return response[:data]['enabled']
        end

        return false
    end

    def enabled_for_user(feature, user_identifier)
        if feature['enabled'] and user_identifier
            if feature['include_users'].length > 0
                if feature['include_users'].include? user_identifier
                    return true
                else
                    return false
                end
            elsif feature['exclude_users'].length > 0
                if feature['exclude_users'].include? user_identifier
                    return false
                else
                    return true
                end
            elsif feature['rollout_target'] > 0
                return false
            end
        elsif not user_identifier and (feature['rollout_target'] > 0 or feature['include_users'].length > 0 or feature['exclude_users'].length > 0)
            return false
        end

        return feature['enabled']
    end

    def cache_is_stale(feature)
        if @cache_timeout == 0
            return true
        end

        cache_expiration = (Time.now.to_i - @cache_timeout)
        if feature['last_sync'] > cache_expiration and @last_dirty_check > cache_expiration
            return false
        end

        if @last_dirty_check < cache_expiration
            return true
        end

        return false
    end

    def api_request(endpoint, params={}, method=:get)
        headers = {
            'Authorization' => "#{@customer_key}:#{@environment_key}"
        }

        begin
            request = Nestful::Request.new(@api + endpoint, :headers => headers, :params => params, :method => method)
            response = request.execute

            if response.status == 200
                data = response.decoded
                result = {
                    'success': true,
                    'message': '',
                    'data': data
                }
            else
                data = response.decoded
                result = {
                    'success': false,
                    'message': data['message'],
                    'status': response.status
                }
            end

            return result
        rescue Nestful::ForbiddenAccess
            result = {
                'success': false,
                'message': 'Authentication Error',
                'status': 403
            }
            return result
        rescue Nestful::ConnectionError
            result = {
                'success': false,
                'message': 'Error communicating with FeatureSwitches',
                'status': -1
            }
            return result
        end
    end

    def do_dirty_check
        Thread.new do
            loop do
                dirty_check()
                sleep(@check_interval)
            end
        end
    end
end

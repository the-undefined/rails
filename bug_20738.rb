begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'rails', path: '.'
  gem 'byebug'
  # gem 'rails', github: 'rails/rails'
  # gem 'arel', github: 'rails/arel'
  # gem 'rack', github: 'rack/rack'
end

require 'rack/test'
require 'action_controller/railtie'
require 'rails/engine'
require 'byebug'

module Blog
  class MyEngine < Rails::Engine
    def self.inspect
      "Blog::Engine"
    end

    routes.draw do
      resources :posts do
        resources :comments
      end
    end
  end

  class PostsController < ActionController::Base
    def index
    end
  end
end

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'cookie_store_key'
  secrets.secret_token    = 'secret_token'
  secrets.secret_key_base = 'secret_key_base'

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    get '/' => 'test#index'

    mount Blog::MyEngine => "/blog", as: "blog"
    namespace :blog do
      get '/news_stories', to: 'news_stories#index'
    end
  end
end

module Blog
  class NewsStoriesController < ActionController::Base
    include Rails.application.routes.url_helpers
    include Rails.application.routes.mounted_helpers

    def index
      # on rails 4.1.9
      # [1] pry(#<Blog::NewsStoriesController>)> blog.posts_path
      # => "/blog/posts"

      # on rails master
      # [1] pry(#<Blog::NewsStoriesController>)> blog.posts_path
      # => "/posts"
      redirect_to blog.posts_path

      # workaround:
      # redirect_to blog.posts_path(script_name: '/blog')
    end
  end
end
require 'minitest/autorun'

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class NewsStoriesControllerTest < ActionController::TestCase
  include Rack::Test::Methods

  test "should redirect to the expected location" do
    response = get '/blog/news_stories'
    assert_equal 302, response.status
    assert_equal "http://example.org/blog/posts", response.headers["location"]
  end

  private
  def app
    Rails.application
  end
end

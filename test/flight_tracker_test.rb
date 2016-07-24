ENV["RACK-ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../flight_tracker.rb"

class FlightTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def setup
    FileUtils.touch(flights_path)
  end

  def teardown
    FileUtils.rm(flights_path)
  end

  def test_home_page_not_signed_in
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Please sign in to access personalized"
    assert_includes last_response.body, %q(<button type="submit">Sign In</button>)
    refute_includes last_response.body, "All Flights"
  end

  def test_home_page_no_flights_signed_in
    get "/", {}, admin_session
    assert_includes last_response.body, "You are currently signed in as admin"
    assert_includes last_response.body, "There are currently no flights to display."
    assert_equal 200, last_response.status
  end

  def test_sign_in_wrong_credentials
    post "/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
  end

  def test_sign_in_right_credentials
    post "/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
  end

  def test_add_flight_not_signed_in

  end

  def test_add_flight_signed_in

  end

  def test_delete_flight_not_signed_in

  end

  def test_delete_flight_signed_in

  end
end
require "test_helper"

class PlexTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::Plex::VERSION
  end

  def test_plex_configure_sets_config
    my_config = {
      port: 1000, host: '192.168.1.1', token: 'token'
    }
    @server = Plex::Server.new(my_config)
    assert_equal 1000, @server.config[:port]
    assert_equal "192.168.1.1", @server.config[:host]
    assert_equal "token", @server.config[:token]
  end

end

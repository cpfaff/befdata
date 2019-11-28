# Fixes:ThreadError: already initialized in tests with rails 4 and
# ruby 2.6
if RUBY_VERSION>='2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # hack to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  else
    puts "Monkeypatch for ActionController::TestResponse no longer needed"
  end
end

class ActionController::LiveTestResponse < ActionController::Live::Response
  def recycle!
    @body = nil
    @mon_mutex_owner_object_id = nil
    @mon_mutex = nil
    initialize
  end
end

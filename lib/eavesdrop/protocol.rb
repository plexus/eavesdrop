module Eavesdrop
  class Protocol
    attr_reader :signals

    def initialize( &blk )
      @signals = []
      append( &blk ) if block_given?
    end

    def append( &blk )
      instance_eval( &blk )
    end

    def send_out( s )
      @signals << s
    end

    def new_listener_list
      ListenerList.new( self )
    end

    def clone
      super.tap do |cln|
        cln.append do
          @signals = @signals.clone
        end
      end
    end
  end
end

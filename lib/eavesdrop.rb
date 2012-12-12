# fire broadcast notify trigger emit tell say voice 

# notify(:boiling)
# notify_boiling

module Eavesdrop
  API = {
    :emit => :notify
  }

  def self.protocol(name = nil, &blk)
    Class.new(Eavesdropper, &blk).support(name)
  end

  class ListenerList < Array
    def initialize(events)
      @events = events
    end

    def method_missing(m, *args)
      if m =~ /#{API[:notify]}_(.*)/ && @events.include?($1.to_sym)
        each do |listener|
          listener.send($1, *args)
        end
      end
    end
  end

  class Eavesdropper
    def self.support(prefix = nil)
      listener_class = self
      ::Module.new do
        listeners = [prefix, 'listeners'].compact.join('_')

        define_method( listeners ) do
          unless instance_variable_defined?( "@#{listeners}" ) 
            instance_variable_set( "@#{listeners}", ListenerList.new( listener_class.protocol ) )
          end
          instance_variable_get( "@#{listeners}" )
        end
      end
    end

    def self.inherited( base )
      base.extend( DSL )
    end
    
    module DSL
      def protocol ; @protocol ||= [] ; end
      
      def listen_for( name )
        protocol << name
      end
      alias send_out listen_for
    end
  end
end

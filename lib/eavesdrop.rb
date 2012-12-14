# fire broadcast notify trigger emit tell say voice 

# notify(:boiling)
# notify_boiling

module Eavesdrop
  API = {
    :emit => :notify
  }

  # module Protocol
  #   def protocol(name = nil, &blk)
  #     include Class.new(Eavesdrop::Eavesdropper, &blk).support(name)
  #   end
  # end

  def self.protocol(name = nil, &blk)
    include Class.new(Eavesdrop::Eavesdropper, &blk).support(name)
  end

  class ListenerList < Array
    attr_accessor :type
    def initialize( type )
      @type = type
    end

    def method_missing(m, *args)
      if m =~ /#{API[:notify]}_(.*)/ && @type.protocol.include?($1.to_sym)
        each do |listener|
          if listener.respond_to? $1
            listener.send($1, *args)
          end
        end
      else
        p @type.protocol
        super(m ,*args)
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
            instance_variable_set( "@#{listeners}", ListenerList.new( listener_class ) )
          end
          instance_variable_get( "@#{listeners}" )
        end

        add_listener = ['add', prefix, 'listener'].compact.join('_')
        define_method( add_listener ) do |listener|
          self.send(listeners) << listener
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

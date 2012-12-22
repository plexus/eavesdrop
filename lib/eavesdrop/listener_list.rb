module Eavesdrop
  class ListenerList < Array
    attr_reader :protocol

    def initialize( protocol )
      @protocol = protocol 
    end
    
    def signals
      protocol.signals
    end

    def notify( signal, *args )
      raise UnknownSignalError.new(signal) unless valid_signal?( signal )
      each {|listener| listener.send( signal, *args ) }
    end

    def valid_signal?( signal )
      signals.include? signal
    end
  end
end

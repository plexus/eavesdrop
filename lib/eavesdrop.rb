require 'eavesdrop/protocol'
require 'eavesdrop/listener_list'

module Eavesdrop  
  def self.included( base )
    base.send(:extend, ClassMethods)
  end

  private

  def notify(*args)
    listeners.notify(*args)
  end

  module ClassMethods
    attr_accessor :protocols

    def inherited( child )
      child.protocols = Hash[ self.protocols.map {|name, protocol| [name, protocol.clone] } ]
    end

    private

    def signals( name = nil, &blk )
      @protocols ||= {}
      @protocols[name] ||= Protocol.new
      @protocols[name].append( &blk )
      define_eavesdrop_methods( name )
    end
    alias listener_support signals

    def define_eavesdrop_methods( name )
      meth_signals      = [name, :signals].compact.join('_') 
      meth_listeners    = [name, :listeners].compact.join('_') 
      meth_add_listener = [:add, name, :listener].compact.join('_') 

      define_method( meth_signals ) do # !> previous definition of signals was here
        self.send( meth_listeners ).signals
      end

      define_method( meth_add_listener ) do | l | # !> previous definition of add_listener was here
        self.send( meth_listeners ) << l
      end

      define_method( meth_listeners ) do # !> previous definition of listeners was here
        @listener_lists ||= {}
        @listener_lists[name] ||= self.class.protocols[name].new_listener_list
      end
    end
  end

  class UnknownSignalError < RuntimeError
    def initialize( signal )
      super( "Signal :#{signal} is not part of this listener list's protocol." )
    end
  end
end

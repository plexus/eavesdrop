module Eavesdrop
  class UnknownSignalError < RuntimeError
    def initialize( signal )
      super( "Signal :#{signal} is not part of this listener list's protocol." )
    end
  end
  
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

############################################################

require 'rspec'

describe Eavesdrop, 'when included' do
  let(:basic_class) do
    Class.new do
      include Eavesdrop
      signals { send_out :something_happened }
    end
  end

  let(:class_with_constructor) do
    Class.new(basic_class) do
      attr_reader :construct_args
      def initialize( a1, a2, a3 )
        @construct_args = [ a1, a2, a3 ]
      end
    end
  end

  let(:class_that_sends_signals) do
    Class.new(basic_class) do
      def do_something(*args)
        notify( :something_happened, *args )
      end
    end
  end

  let(:instance) { basic_class.new }
  
  describe "#signals" do
    it "should return a list of the signals an object emits" do
      instance.signals.should == [ :something_happened ]
    end

    it "should instantiate a listener list" do
      instance.listeners.should_not be_nil
    end

    context "with an exisiting constructor" do
      let(:instance) { class_with_constructor.new(7, :b, 'q') }
      it "should behave as with the original constructor" do
        instance.construct_args.should == [7, :b, 'q']
      end
    end
  end

  describe "#add_listener" do
    it "should add a listener to the listener list" do
      instance.add_listener :sentinel
      instance.listeners.should == [ :sentinel ]
    end
  end

  describe "notify" do
    let(:instance) {class_that_sends_signals.new}
    let(:listener) {double('listener')}
    it "should notify registered listeners" do
      listener.should_receive(:something_happened)
      instance.add_listener listener
      instance.do_something
    end
  end  

  context "when having multiple signal blocks" do
    let(:basic_class) do
      Class.new do
        include Eavesdrop
        signals { send_out :something_happened }
        signals { send_out :something_else }
      end
    end

    it "should merge them together" do
      instance.listeners.signals.should =~ [:something_happened, :something_else]
    end

    context "in a subclass" do
      let(:inherited_class) do
        Class.new(basic_class) do
          signals { send_out :something_more }
        end
      end

      let(:inherited_instance) {inherited_class.new}

      it "should merge them together" do
        inherited_instance.listeners.signals.should =~ [:something_happened, :something_else, :something_more]
      end

      it "should not touch the base class" do
        inherited_instance # so it's evaluated
        instance.listeners.signals.should =~ [:something_happened, :something_else]
      end

    end
  end

end

describe Eavesdrop::Protocol do
  let(:simple_protocol) { Eavesdrop::Protocol.new {send_out :test} }
  it "should take a block in its initializer to specify signals" do
    simple_protocol.signals.should == [:test]
  end

  describe "#new_listener_list" do
    it "should act as a factory for listener lists" do
      simple_protocol.new_listener_list.should_not be_nil
    end

    it "should link the listener list back to the protocol" do
      simple_protocol.new_listener_list.protocol.should == simple_protocol
    end
  end
end

describe Eavesdrop::ListenerList do
  let(:protocol) { Eavesdrop::Protocol.new{ send_out :signal1; send_out :signal2 } }
  let(:listener_list) { Eavesdrop::ListenerList.new(protocol) }
  let(:listener) { double 'listener' }
  it "should keep a list of supported signals" do
    listener_list.signals.should == [:signal1, :signal2]
  end
  describe "#notify" do
    it "should do nothing when there are no listeners to notify" do
      listener_list.notify( :signal1 )
    end
    it "should be able to pass notification to listeners" do
      listener.should_receive( :signal1 )
      listener_list << listener
      listener_list.notify( :signal1 )
    end
    it "should pass arguments when notifying listeners" do
      listener.should_receive( :signal1 ).with(:a_value)
      listener_list << listener
      listener_list.notify( :signal1, :a_value )
    end
    it "should notify multiple listeners" do
      listeners = [ double('listener'), double('listener') ]
      listeners.each {|listener| listener.should_receive( :signal1 ).with(:a_value) }
      listener_list << listeners.first
      listener_list << listeners.last
      listener_list.notify( :signal1, :a_value )
    end
    it "should raise an error when using an undefined signal" do
      expect { listener_list.notify :unkown_signal }.to raise_error( Eavesdrop::UnknownSignalError )
    end
  end
  describe "#valid_signal?" do
    it "should check if a signal is part of the protocol" do
      listener_list.valid_signal?(:signal1).should be_true
      listener_list.valid_signal?(:chunky_bacon).should be_false
    end
  end
end

describe Eavesdrop, 'named protocols' do
  let :basic_class do
    Class.new do
      include Eavesdrop
      signals :record do
        send_out :added
        send_out :removed
      end

      def add_record(r)
        record_listeners.notify(:added, r)
      end
    end
  end
  let(:instance) { basic_class.new }
  let(:listener) { double('record_listener') }
  let(:record)   { double('record') }

  it "should prefix #add_listener" do
    instance.add_record_listener( listener )
  end

  it "should prefix #listeners" do
    listener.should_receive( :added ).once.with( record )
    instance.add_record_listener( listener )
    instance.add_record( record )
  end
end

RSpec::Core::Runner.run([]) #(['--format', 'd'])


# >> ....................
# >> 
# >> Finished in 0.00627 seconds
# >> 20 examples, 0 failures

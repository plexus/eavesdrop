require 'spec_helper'

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

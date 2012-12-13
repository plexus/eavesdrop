require 'spec_helper'

class KettleListener < Eavesdropper
  listen_for :boiling
  listen_for :full
end

class Kettle
  include KettleListener.support

  def initialize( capacity = 20 )
    @capacity = capacity
    @content = 0
    @temperature = 0
  end

  def heat
    @temperature = [@temperature + 10, 100].min
    listeners.notify_boiling if @temperature == 100
  end

  def fill( amount = 5 )
    @content = [ @content + amount, @capacity ].min
    listeners.notify_full if @content == @capacity
  end
end

class Waiter < KettleListener
  def full
    puts 'kettle is full'
  end

  def boiling
    puts 'kettle is boiling'
  end
end

describe 'eavesdropper' do
  let ( :kettle ) { Kettle.new }
  let ( :listener ) { Waiter.new }

  before { kettle.listeners << listener }

  it "should receive events" do
    listener.should_receive(:full).once
    kettle.fill( 20 )
  end
end


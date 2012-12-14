# Eavesdrop on your Ruby classes

![Decouple all the things](https://raw.github.com/arnebrasseur/eavesdrop/master/all_the_things.jpg)

## What?

You can call them Observers, Listeners or Subscriber objects. We call them Eavesdroppers.

## You may be asking

Who needs this? Rolling your own listener support is trivial.

> Less boilerplate, more sugar please.

How about Ruby's built-in Observable?

> It's quite limited, for instance it only broadcasts one message : #update.

## Features of Eavesdrop

- Declaratively specify the protocol a type of listeners understands, so you also have a place to document it.
- Adding listener support to a class is a one-liner.
- Support multiple protocols (listener types) in one class.
- Any class that implements the specified methods can be a listener, you don't need a specific base class. So you can do stuff like inheriting from SimpleDelegator.

## Explicit listener types

```ruby
class TemperatureListener < Eavesdrop::Eavesdropper
  listen_for :temperature_changed
end

class Weather
  include TemperatureListener.support( :heat )
    # defines methods #heat_listeners and #add_heat_listener

  def heat_up
    @heat ||= 0
    @heat += 2
    heat_listeners.notify_temperature_changed( @heat )
		 # calls #temperature_changed( @heat ) on each listener
  end
end

Weather.new.tap do |w|
  w.add_heat_listener( Class.new { def temperature_changed( deg ); puts "it's now #{deg} degrees" ; end }.new )
  w.heat_up
  w.heat_up
end
```

## Anonymous listener types

```ruby
class Weather
  include Eavesdrop.protocol(:heat) {
    send_out :temperature_changed
  }

  def heat_up
    @heat ||= 0
    @heat += 2
    heat_listeners.notify_temperature_changed( @heat )
  end
end

Weather.new.tap do |w|
  w.add_heat_listener( Class.new { def temperature_changed( deg ); puts "it's now #{deg} degrees" ; end }.new )
  w.heat_up
  w.heat_up
end
```
## Caveat

This is an experiment to see where turning this simple pattern into a proper library might lead to. The API will probably still change significantly. Ideas/suggestions are very welcome.

## Further reading

- [Observer pattern terminology](https://gist.github.com/3842243)

## Alternatives

- Observable / Observer from the standard library
- [atomicobject/publisher](https://github.com/atomicobject/publisher)

## License

http://opensource.org/licenses/MIT
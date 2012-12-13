# Eavesdrop on your Ruby classes

![Decouple all the things](https://raw.github.com/arnebrasseur/eavesdrop/master/all_the_things.jpg)

## Design goals

- have a way to specify the protocol your listeners understand
- listeners are POROs that implement these as methods

## Explicit listener types

    class TemperatureListener < Eavesdrop::Eavesdropper
      listen_for :temperature_changed
    end

    class Weather
      include TemperatureListener.support( :heat )

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

## Anonymous listener types

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

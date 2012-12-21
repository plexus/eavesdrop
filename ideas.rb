include Eavesdrop.protocol {
  # Automatic notifications before/after methods
  send_out :record_added, :after => :add_record
}
# This will probably require that you add this block after your methods are defined

# map message names

collection.add_listener( SomeListener, :added => :item_added )

class SomeListener
  def itemadded(*) ; ... ; end
end

# prefix messages names

collection.add_listener( SomeListener, :prefix => :item )

# Still unsure about which form to use

listeners.notify_bla
listeners.notify( :bla, ...)
listeners.fire( :bla, ...)
listeners.bla


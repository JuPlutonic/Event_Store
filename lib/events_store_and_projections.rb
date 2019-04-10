require 'pp'

# * event - event what already happend
# * event store - event storage place
# * projection - think that collect the state
# * producer - abstraction what creates events
#

# Event
#
# * happen in the past
# * data object
# * обязательно имя и данные
# * can be any type hash, array, etc.
module Events
  class Base
    attr_reader :payload

    def initialize(payload:)
      @payload = Hash(payload)
    end
  end

  # Order logic
  class ItemAddedToOrder < Base; end
  class ItemRemovedFromOrder < Base; end
  class OrderCreated < Base; end
  class OrderClosed < Base; end
  class OrderCheckouted < Base; end
end

# event store
#  * immutable - we transmitted all
#      from the very beginning, event can't be deleted
# interface:
# * get (nil -> list of events)
# * append (list of events -> nil)
class EventStore
  def initialize
    @store = []
  end

  def get
    @store
  end

# ENVOLVE IS BETTER (than append) BECAUSE IT USING PRODUCER
  def append(*events)
    puts '<' * 80
    events.each { |event| @store << event }
  end
  def envolve(producer, payload)
    @store
    new_events = producer.call(@store, payload)
    @store = @store + new_events
  end

end

# projection
# * pure function
#
# * f(g, initial_state, event_list) -> state
# * f(g, state,         event_list) -> new state
#
# * f -> project
# * g -> projection
#
module Projections
  # project(projection, initial_state, event_list) -> state
  # inject / reduce defines call to itsels
  class Project
    def call(projection, initial_state, events)
      events.reduce(initial_state) { |state, event| projection.call(state, event)}
    end
  end

  # TODO: refacotor 2nd case 'when' with smth much more easier
  # (im) true mutable paradigm, modifying state
  # Producer what collects order-events
  class AllOrders
    def call(state, event)
      case event
      when Events::OrderCreated
      	state[:orders] ||= [] # array el-mnts got order numbers
      	state[:orders] << { **event.payload, items: [] }
      when Events::ItemAddedToOrder
        order = state[:orders].select { |o| o[:order_id] == event.payload[:order_id] }.first
        state[:orders].delete_if { |o| o[:order_id] == event.payload[:order_id] }.first

        order[:items] << event.payload
        state[:orders] << order
      end

      state
    end
  end

  # TODO: 2.7 use Enumerable#tally
  # Tally cost of orders
  class CostForOrders
    def call(state, event)
      case event
      when Events::OrderCreated
        state[:order_costs] ||= {}
        state[:order_costs][event.payload[:order_id]] = 0
      when Events::ItemAddedToOrder
        # can be implemented with help of streams
        state[:order_costs][event.payload[:order_id]] += event.payload[:cost]
      end

      state
    end
  end
end

###############################################
#            AllOrders                        #
#
# p '*' * 40 # event_store creation
# event_store = EventStore.new
# project = Projections::Project.new

# puts 'Initial state:'
# events = event_store.get
# p project.call(Projections::AllOrders.new, {}, events)

# puts "\nAfter creating order:"
# event = Events::OrderCreated.new(payload: { order_id: 1, account_id: 1 })
# event_store.append(event)
# events = event_store.get
# p project.call(Projections::AllOrders.new, {}, events)

# puts "\nAfter creating one more order:"
# event = Events::OrderCreated.new(payload: { order_id: 2, account_id: 1 })
# event_store.append(event)
# events = event_store.get
# p project.call(Projections::AllOrders.new, {}, events)

###############################################
# Lifehack - any init state can be transmitted#
#
# p '*' * 40
# event_store = EventStore.new
# project = Projections::Project.new

# puts 'Initial state:'
# events = event_store.get
# p project.call(Projections::AllOrders.new, {}, events)

# puts "\nYesterday's orders:"
# event = Events::OrderCreated.new(payload: { order_id: 1, account_id: 1 })
# event_store.append(event)
# yesterdays_events = event_store.get
# p yesterdays_orders = project.call(Projections::AllOrders.new, {}, yesterdays_events)

# puts "\nCreating today's orders:"
# event_store = EventStore.new
# event = Events::OrderCreated.new(payload: { order_id: 2, account_id: 1 })
# event_store.append(event)
# events = event_store.get
# p project.call(Projections::AllOrders.new, yesterdays_orders, events)

###############################################
# CostForOrders                               #
#


#LAST COMMENTED OFF


# p '*' * 40
# event_store = EventStore.new
# project = Projections::Project.new
# event = Events::OrderCreated.new(payload: { order_id: 1, account_id: 1 })
# event_store.append(event)
# event = Events::OrderCreated.new(payload: { order_id: 2, account_id: 2 })
# event_store.append(event)

# puts 'Added 2 orders:'
# events = event_store.get
# pp project.call(Projections::AllOrders.new, {}, events)

# p '*' * 40
# event = Events::ItemAddedToOrder.new(payload: { order_id: 1, item_id: 1, name: 'ruby sticker', cost: 10 })
# event_store.append(event)
# event = Events::ItemAddedToOrder.new(payload: { order_id: 1, item_id: 2, name: 'git sticker', cost: 17 })
# event_store.append(event)
# event = Events::ItemAddedToOrder.new(payload: { order_id: 2, item_id: 3, name: 'ruby sticker', cost: 11 })
# event_store.append(event)

# puts "\nAdded stickers. Added cost:"
# events = event_store.get
# pp project.call(Projections::AllOrders.new, {}, events)

# puts "\nTally cost of orders:"
# pp project.call(Projections::CostForOrders.new, {}, events)

# TODO: добавлю ID - в DevOps't важно всем ивентам давать id
# Для соотв. з-нам ЕС есть 2 варианта реализации:
# 1. Мартин Паули - держать хэшированный ключ, а потом выкидывать
# 2. GDPR (3 разных стейта)

require 'securerandom'

module Producers
  # payload:
  #   account_id
  #   name
  #   cost
  class AddItem
    def initialize
      @project = Projections::Project.new
    end

    def call(events, payloads)
      state = project.call(Projections::AllOrders.new, {}, events)
      orders = state[:orders]

      orders_for_account = order.select { |order| order[:account_id] == payload[:account_id] }.first

      if order_for_account
        [
          Events::ItemAddedToOrder.new(
            payload: {
              order_id: order_for_account[:order_id], item_id: SecureRandom.uuid, name: payload[:name], cost: payload[:cost]
            }
          )
        ]
        # add item
      else
        order_id = SecureRamdom.uuid

        [ Events::OrderCreated.new(
            payload: {
              order_id: order_id, account_id: 2
            }
          ),
          Events::ItemAddedToOrder.new(
            payload: {
              order_id: order_id, item_id: SecureRandom.uuid, name: payload[:name], cost: payload[:cost]
            }
          )
        ]
        # create order + add item
      end
    end
  end
end

event_store = EventStore.new
project = Projections::Project.new

event = Events::OrderCreated.new(payload: {order_id: 1, account_id: 1} )
event_store.append(event)
puts '*' * 80
event_store.envolve( Producers::AddItem.new, account_id: 1, name: 'ruby sticker', cost: 10 )
event_store.envolve( Producers::AddItem.new, account_id: 2, name: 'hanami sticker', cost: 5 )
event_store.envolve( Producers::AddItem.new, account_id: 2, name: 'ruby sticker', cost: 15 )
# create order w/ item
# -> OrderCreated
# -> ItemAddedToOrder

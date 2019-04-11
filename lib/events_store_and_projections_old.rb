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
# * consist of minimum two parts: name and data
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
#
# * immutable - we transmitted all
#     from the very beginning, event can't be deleted
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

  # EventStore.append doesn't use Producer
  def append(*events)
    puts '<' * 80
    events.each { |event| @store << event }
  end

  # EventStore.envolve is better than append
  def envolve(producer, payload)
    @store
    new_events = producer.call(@store, payload)
    @store += new_events
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
  # inject / reduce defines call to itselvs
  class Project
    def call(projection, initial_state, events)
      events
        .reduce(initial_state) { |state, event| projection.call(state, event) }
    end
  end

  # TODO: refacotor 2nd 'when'in 'case' block with smth much more easier
  # (im) true mutable paradigm, modifying state
  # Producer what collects order-events
  class AllOrders
    def call(state, event)
      case event
      when Events::OrderCreated
        state[:orders] ||= [] # array el-mnts got order numbers
        state[:orders] << { **event.payload, items: [] }
      when Events::ItemAddedToOrder
        order = state[:orders]
                .select { |o| o[:order_id] == event.payload[:order_id] }
                .first
        state[:orders]
          .delete_if { |o| o[:order_id] == event.payload[:order_id] }
          .first

        order[:items] << event.payload
        state[:orders] << order
      end

      state
    end
  end

  # TODO: 2.7 use Enumerable#tally to tally cost of orders
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

require 'securerandom'

# producer
#
# P. incapsulates logic of event creation, prevents inconsistencies like
# creation of not completed event part (eg. Order w/o Item)
#
# * create order w/ item
#   -> OrderCreated
#   -> ItemAddedToOrder
module Producers
  class AddItem
    def initialize
      @project = Projections::Project.new
    end

    # payload:
    #   account_id
    #   name
    #   cost
    def call(events, payload)
      state = @project.call(Projections::AllOrders.new, {}, events)
      orders = state[:orders]

      account_order = orders
                      .select { |o| o[:account_id] == payload[:account_id] }
                      .first

      if account_order
        [
          Events::ItemAddedToOrder.new(
            payload: {
              order_id: account_order[:order_id],
              item_id: SecureRandom.uuid,
              name: payload[:name],
              cost: payload[:cost]
            }
          )
        ]
        # add item
      else
        order_id = SecureRandom.uuid

        [Events::OrderCreated.new(
          payload: {
            order_id: order_id, account_id: payload[:account_id]
          }
        ),
         Events::ItemAddedToOrder.new(
           payload: {
             order_id: order_id,
             item_id: SecureRandom.uuid,
             name: payload[:name],
             cost: payload[:cost]
           }
         )]
        # create order + add item
      end
    end
  end
end

###############################################
# 1. Test for creating orders
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
# 2. Test of pipelining of two events
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
# 3. Test of pipelining of 3 events + summarize
# CostForOrders                               #
#
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

###############################################
# 4.Test event creation with help of Producers
# Using EventStore.envolve to call producer   #
# and send to it arguments (payload)
#
p '*' * 80
event_store = EventStore.new
project = Projections::Project.new
events = event_store.get
pp project.call(Projections::AllOrders.new, {}, events)

event = Events::OrderCreated.new(payload: { order_id: SecureRandom.uuid, account_id: 1 })
event_store.append(event)

event_store.envolve(Producers::AddItem.new, account_id: 1, name: 'ruby sticker', cost: 10)
event_store.envolve(Producers::AddItem.new, account_id: 2, name: 'hanami sticker', cost: 5)
event_store.envolve(Producers::AddItem.new, account_id: 2, name: 'ruby sticker', cost: 15)

events = event_store.get
pp project.call(Projections::AllOrders.new, {}, events)

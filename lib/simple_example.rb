class Main
end

# event_store = []
# event_store << { name: 'add item', payload: { cost:  4, order_id: 1 }}
# event_store << { name: 'add item', payload: { cost: 10, order_id: 1 }}
# event_store << { name: 'add item', payload: { cost:  7, order_id: 1 }}
# event_store << { name: 'add item', payload: { cost: 11, order_id: 2 }}

# order_total_cost = 0
# event_store.each do |event|
#   if event[:payload][:order_id] == 1
#   	order_total_cost += event[:payload][:cost]
#   end
# end

# order_items_total_count = 0

# #p event_store

# event_store.each do |event|
#   if event[:name] == 'add item'
#   	order_items_total_count += 1
#   end
# end

#   puts "Total cost for order#1 - #{order_total_cost}"
#   puts "Order #1 has #{order_items_total_count} items"
#
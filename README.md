# Event_Store
Event Store: Stickers store. All code placed in /lib/events_store_and_projections.rb

# @davydovanton links:

Explanation what is event soursing:

https://dev.to/barryosull/event-sourcing-what-it-is-and-why-its-awesome

Information from microservices.io:

http://microservices.io/patterns/data/event-sourcing.html

Event-driven architectural patterns:

https://www.ultrasaurus.com/2017/12/event-driven-architectural-patterns/

An Introduction to Event Sourcing for Rubyists:

https://speakerdeck.com/mottalrd/an-introduction-to-event-sourcing-for-rubyists

Event Sourcing made Simple from kickstarter engineers:

https://kickstarter.engineering/event-sourcing-made-simple-4a2625113224

Microsoft docs:

https://docs.microsoft.com/en-us/azure/architecture/patterns/event-sourcing

Module learning of ES (Also continuation of links):

https://github.com/jennaleeb/event_sourcing_for_everyone

# Videos

1. [Applying CQRS & Event Sourcing on Rails applications - Andrzej Śliwa - wroc_love.rb 2018:](https://www.youtube.com/watch?v=cdwX1ZU623E) (description)

- Normalizer is not equal EventHandler

- Speaker mentioned Infrastructure(Infra module)/Plumbing (maybe `saga.rb`) for RailsEventStore 

- Speaker told about [Fault tolerance for errors on event handlers, Infra::EventHandlerErrorStrategy](https://github.com/RailsEventStore/rails_event_store/issues/111)

- See the mindmap with use-cases from the presentation on 38:03

2. Nathan Ladd from Eventide(`eventide-project.org` is an Event-Sourced Automous Services):

- [Event Sourcing Anti Patterns and Failures - wroc_love.rb 2018](https://www.youtube.com/watch?v=vh1QTk34350)

- [Some DDD-patterns eg: Aggregate:](https://www.youtube.com/watch?v=sb-WO-KcODE)

# Tools

Event-sourcing, event-store examples:
https://github.com/eventide-project (see pinned, eventide-project/docs)

DB:
https://eventstore.org (The stream database written from the ground up for event sourcing)

Fullstack:
https://railseventstore.org (!!!)
https://github.com/zilverline/sequent

Transport:
https://github.com/karafka/karafka
https://github.com/hanami/events
https://github.com/davydovanton/ivento (Simple event sourcing framework in functional style)

# TODO

Watch some videos:

```
1.https://www.youtube.com/watch?v=veTVAN0oEkQEvent Storming - Alberto Brandolini - wroc_love.rb 2015
event storming invented by Andolini (visually similar to Trello and Wekan - the Kanban board)
2.https://www.youtube.com/watch?v=Rh2A96rpGpY
Panel - CQRS & Event Sourcing & DDD - wroc_love.rb 2015
...
10.https://www.youtube.com/watch?v=ZMLQNocd2zU
An Event Sourcing Retrospective - lecture by Dennis Doomen - Code Europe Autumn 2017
                                          from AvivaSolutions
11.https://www.youtube.com/watch?v=GzrZworHpIk
Event Sourcing You are doing it wrong by David Schmitz from Senacor Technologies 2018
12.https://www.youtube.com/watch?v=1h3_6ATnOTw
Event Sourcing for Everyone by Jenna Blum from Shopify Paris.rb 2018
```

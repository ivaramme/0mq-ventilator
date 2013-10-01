Small example of the usage of zero-mq as a ventilator (aka coordinator) to dispatch messages to multiple clients (aka workers)

####Roles
Coordinator: accepts connections from workers and sends messages in a round-robin distribution, which means different messages will get to different clients.
Worker: connects to a coordinator and waits for messages. Once a message is received publishes an update of status
```
Coordinator -- sends message --> 
                                < cluster of workers, 1 message per worker >
                                 Worker - receives and processes messages
                                 Worker - receives and processes messages
                                 Worker - receives and processes messages
                                < ---------------------------------------- >
           <-- each one sends ack  --  (this could be some other message and doesn't have to be right away)
```
####Instructions:

Open a console window and try:

To start as a coordinator:
./manager.rb --role coordinator

To start as a worker:
./manager.rb --role worker

You can open multiple tabs with workers.
In the coordinator's tab, type in a command and press enter. You can add workers at any time and messages will get delived in order. To end a worker, type 'end'

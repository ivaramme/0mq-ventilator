Small example of the usage of zero-mq as a ventilator to dispatch messages to multiple clients (aka workers)

Roles:
Coordinator: accepts connections from workers and sends messages in a round-robin distribution, which means different messages will get to different clients.
Worker: connects to a coordinator and waits for messages. Once a message is received publishes an update of status

Coordinator -- send message --> Worker
                                    receive message and process
           <-- send ack     --  (this could be some other message and doesn't have to be right away)

Instructions:
From console try:

To start as a coordinator:
./manager.rb --role coordinator

To start as a worker:
./manager.rb --role worker

You can open multiple tabs with workers.
In the coordinator tab, type in a command and press enter. To end a worker, type 'end'
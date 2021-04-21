defmodule Debug do
    def print_debug(state, parameters) do
        case state do
            :hw_order ->
                
                IO.inspect("New order received from HW: ")
                IO.inspect(parameters)

            :new_order_single_elevator ->
                
                IO.inspect("New order in single elevator: ")
                IO.inspect(parameters)

            :new_cab_order_ptp_elevator ->
                
                IO.inspect("New cab order in ptp-mode to floor: ")
                IO.inspect(parameters)

            :new_order_ptp_elevator ->
                
                IO.inspect("The order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.inspect("has been assigned to: ")
                IO.inspect(Enum.at(parameters, 1))

            :take_this_order ->
                
                IO.inspect("I've been told to take order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.inspect("From: ")
                IO.inspect(Enum.at(parameters, 1))

            :log_this_order ->
                
                IO.inspect("I am logging order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.inspect("From: ")
                IO.inspect(Enum.at(parameters, 1))

            :orders_served ->
                
                IO.inspect("I am clearing logged orders at floor: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.inspect("From node: ")
                IO.inspect(Enum.at(parameters, 1))

            :calculate_cost ->
                
                IO.inspect("I am calculating cost for order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.inspect("From: ")
                IO.inspect(Enum.at(parameters, 1))

            :give_active_cab_calls_of_node ->
                
                IO.inspect("I am giving back cab-calls to elevator: ")
                IO.inspect(parameters)

            :give_active_orders ->
                
                IO.inspect("I am giving my active orders to elevator: ")
                IO.inspect(parameters)

            :recovering_cab_calls ->
                
                IO.inspect("Attempting to recover cab-calls")

            :recovering_order_logger ->
                
                IO.inspect("Attempting to recover BackupQueue")

            :accepting_order ->
                IO.inspect("I am accepting order ")
                IO.inspect(parameters)

            :opening_socket ->
                
                IO.inspect("Opening udp-socket")

            :received_udp_msg ->
                
                IO.inspect("Recieved this over udp: ")
                IO.inspect(parameters)

            :closing_socket ->
                
                IO.inspect("Closing udp-socket")

            :ping_peers_now ->
                IO.write("My peers are")
                IO.inspect(Enum.at(parameters, 0))
                IO.write("They have failed to respond this many times: ")
                IO.inspect(Enum.at(parameters, 1))
                IO.inspect("Pinging peers!")

            :starting_timer ->
                IO.write("Starting timer: ")
                IO.inspect(parameters)

            :stopping_timer ->
                IO.write("Stopping timer: ")
                IO.inspect(parameters)

            :timer_timedout ->
                IO.write("Timer ")
                IO.inspect(parameters)
                IO.write("Timed out!")
        end
    end
end
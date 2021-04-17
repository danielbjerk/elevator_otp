defmodule Debug do
    def print_debug(state, parameters) do
        case state do
            :hw_order ->
                IO.inspect("-----------------------------------------")
                IO.write("New order received from HW: ")
                IO.inspect(parameters)

            :new_order_single_elevator ->
                IO.inspect("-----------------------------------------")
                IO.write("Accepting order in single elevator: ")
                IO.inspect(parameters)

            :new_cab_order_ptp_elevator ->
                IO.inspect("-----------------------------------------")
                IO.write("Accepting cab order in ptp-mode to floor: ")
                IO.inspect(parameters)

            :new_order_ptp_elevator ->
                IO.inspect("-----------------------------------------")
                IO.inspect("The order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.write("has been assigned to: ")
                IO.inspect(Enum.at(parameters, 1))

            :take_this_order ->
                IO.inspect("-----------------------------------------")
                IO.write("I've been told to take order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.write("From: ")
                IO.inspect(Enum.at(parameters, 1))

            :log_this_order ->
                IO.inspect("-----------------------------------------")
                IO.write("I am logging order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.write("From: ")
                IO.inspect(Enum.at(parameters, 1))

            :orders_served ->
                IO.inspect("-----------------------------------------")
                IO.write("I am clearing logged orders at floor: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.write("From node: ")
                IO.inspect(Enum.at(parameters, 1))

            :calculate_cost ->
                IO.inspect("-----------------------------------------")
                IO.write("I am calculating cost for order: ")
                IO.inspect(Enum.at(parameters, 0))
                IO.write("From: ")
                IO.inspect(Enum.at(parameters, 1))

            :give_active_cab_calls_of_node ->
                IO.inspect("-----------------------------------------")
                IO.write("I am giving back cab-calls to elevator: ")
                IO.inspect(parameters)

            :give_active_orders ->
                IO.inspect("-----------------------------------------")
                IO.write("I am giving my active orders to elevator: ")
                IO.inspect(parameters)

            :recovering_cab_calls ->
                IO.inspect("-----------------------------------------")
                IO.write("Attempting to recover cab-calls")

            :recovering_order_logger ->
                IO.inspect("-----------------------------------------")
                IO.write("Attempting to recover OrderLogger")

            :accepting_order ->
                IO.write("I am accepting order ")
                IO.inspect(parameters)

            :opening_socket ->
                IO.inspect("-----------------------------------------")
                IO.inspect("Opening udp-socket")

            :received_udp_msg ->
                IO.inspect("-----------------------------------------")
                IO.write("Recieved this over udp: ")
                IO.inspect(parameters)

            :closing_socket ->
                IO.inspect("-----------------------------------------")
                IO.inspect("Closing udp-socket")

            :ping_peers_now ->
                IO.inspect("-----------------------------------------")
                IO.inspect("Pinging peers!")
        end
    end
end
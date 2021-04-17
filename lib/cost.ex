defmodule Cost do

    def add_distance_cost(cost, position, order) do # Add cost due to distance between current position and order position.
        {elevator_floor, _elevator_direction} = position
        {order_floor, _order_direction} = order
        cost + Kernel.abs(order_floor - elevator_floor) * 2
    end

    def add_queue_length_cost(cost, q) do   # Add cost due to current length of queue
        cost + tuple_size(q) * 1
    end


    def add_direction_cost(cost, order) do  # Add cost due to direction of order. Can result in :no_cost.
        {order_floor, order_direction} = order
        if Queue.order_compatible_with_direction_at_floor?(order_floor, order_direction) do
            :no_cost
        else
            cost + 10
        end
    end

    def calculate_cost_for_order(order) do

        try do

            pTask = Task.async(fn -> Position.get() end)
            position = Task.await(pTask, timeout: 100)

            qTask = Task.async(fn -> Queue.get() end)
            q = Task.await(qTask, timeout: 100)

            add_distance_cost(0, position, order)
            |> add_queue_length_cost(q)
            |> add_direction_cost(order)


        rescue

            :timeout -> :infinite_cost    # Failed to retrieve position for elevator.

            e ->
                IO.puts("Something went wrong")
                IO.inspect(e)
                :error

        end

    end


end
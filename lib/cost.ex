defmodule Cost do

    def add_distance_cost(cost, position, order) do # Add cost due to distance between current position and order position.
        {elevator_floor, _elevator_direction} = position
        {order_floor, _order_direction, :order} = order
        cost + Kernel.abs(order_floor - elevator_floor) * 2
    end

    def add_queue_length_cost(cost, q) do   # Add cost due to current length of queue
        cost + length(q) * 1
    end

    def add_compatibility_cost(cost, order) do  # Add cost due to direction of order. Can result in :no_cost.
        {order_floor, order_direction, :order} = order
        if Queue.order_compatible_with_direction_at_floor?(order_floor, order_direction) do
            cost - 5
        else
            cost + 10
        end
    end

    def add_direction_cost(cost, order, position) do
        {order_floor, order_direction, :order} = order
        {floor, direction} = position
        same_direction = ((order_floor - floor) * order_direction_to_signed_int(order_direction))
        cond do
            same_direction == 0 -> cost - 30
            same_direction > 0 -> cost - 10
            same_direction < 0 -> cost + 10
        end
    end


    def calculate_cost_for_order(order) do

        try do

            pTask = Task.async(fn -> Position.get() end)
            position = Task.await(pTask, 100)

            qTask = Task.async(fn -> Queue.get() end)
            q = Task.await(qTask, 100)

            add_distance_cost(0, position, order)
            |> add_queue_length_cost(q)
            |> add_compatibility_cost(order)
            |> add_direction_cost(order, position)


        rescue

            :timeout -> :infinite_cost    # Failed to retrieve position for elevator.

            e ->
                IO.puts("Something went wrong. Error:")
                IO.inspect(e)
                IO.puts("End-error")
                :error
                

        end

    end

    def order_direction_to_signed_int(dir) do
        case dir do
            :hall_up -> 1
            :hall_down -> -1
        end
    end

end
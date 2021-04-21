defmodule Cost do
    @moduledoc """
    Module for calculating cost of an order. Lower = better.
    """

    def calculate_cost_for_order(order) do

        try do

            pTask = Task.async(fn -> Position.get() end)
            position = Task.await(pTask, 100)

            qTask = Task.async(fn -> Queue.get() end)
            q = Task.await(qTask, 100)

            tTask = Task.async(fn -> RepeatingTimeout.get_time(:detect_power_loss) end)
            time_power_lost_ms = Task.await(tTask, 100)

            add_distance_cost(0, position, order)
            |> add_queue_length_cost(q)
            |> add_compatibility_cost(order)
            |> add_direction_cost(order, position)
            |> add_power_loss_cost(time_power_lost_ms)

        rescue

            :timeout -> :infinite_cost

            e ->
                IO.puts("Something went wrong. Error:")
                IO.inspect(e)
                IO.puts("End-error")
                :error

        end

    end


    # Cost modifiers

    def add_distance_cost(cost, position, order) do # Add cost due to distance between current position and order position.
        {elevator_floor, _elevator_direction} = position
        {order_floor, _order_direction, :order} = order
        cost + Kernel.abs(order_floor - elevator_floor) * 3.5
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
            same_direction > 0 -> cost - 5
            same_direction < 0 -> cost + 5
        end
    end

    def add_power_loss_cost(cost, time_power_lost_ms) do
        cost + 10 * (time_power_lost_ms/1000)
    end


    # Helper function

    def order_direction_to_signed_int(dir) do
        case dir do
            :hall_up -> 1
            :hall_down -> -1
        end
    end

end
defmodule Cost do
    def calculate_cost_for_order(order) do

        try do

            pTask = Task.async(fn -> Position.get() end)
            {elevator_floor, elevator_direction} = Task.await(pTask, timeout: 100)

            try do

                qTask = Task.async(fn -> Queue.get() end)
                q = Task.await(qTask, timeout: 100)

                case order do
        
                    {order_floor, order_direction, :order} ->
                        case order_direction do
                            {elevator_direction} ->
                                case order_direction do

                                    {:hall_up} ->
                                        if Queue.active_orders_above_floor?(elevator_floor) do
                                            order_floor - elevator_floor
                                        end
                                        order_floor + elevator_floor

                                    {:hall_down} ->
                                        if Queue.active_orders_below_floor?(elevator_floor) do
                                            order_floor - elevator_floor
                                        end
                                        order_floor + elevator_floor

                                end
                        end
        
                    {_order_floor, :cab, :order} -> 
                        :no_cost

                    {_order_floor, _type, :no_order} -> 
                        :infinite_cost

                end
    

            rescue
                _e -> :infinite_cost    # Failed to retrieve queue for elevator.
            end

        rescue
            _e -> :infinite_cost    # Failed to retrieve position for elevator.
        end

    end
end
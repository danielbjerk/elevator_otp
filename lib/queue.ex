defmodule Queue do  # TODO: Gå gjennom og fjern alle unødvendige funksjone
  @moduledoc """
  Agent which stores and deals with accessing the queue.
  Orders are tuples on the form {int floor, atom order_type, atom order/no_order}
  """

  use Agent



  # Starting the queue

  def start_link(_opts) do
    {:ok, _agent} = Agent.start_link(Queue, :generate_empty_queue, [], name: __MODULE__)
  end

  def generate_empty_queue do
    Enum.map(Constants.all_floors_range, fn floor -> [{floor, :hall_up, :no_order}, {floor, :hall_down, :no_order}, {floor, :cab, :no_order}] end)
  end



  # Accessing and modifying the queue

  def get do
    Agent.get(__MODULE__, fn queue -> queue end)
  end

  def add_order(order) do
    Agent.update(__MODULE__, __MODULE__, :update_order_in_queue, [order])
  end

  def remove_all_orders_to_floor(floor) do
    Agent.update(__MODULE__, Queue, :update_order_in_queue, [{floor, :hall_up, :no_order}])
    Agent.update(__MODULE__, Queue, :update_order_in_queue, [{floor, :hall_down, :no_order}])
    Agent.update(__MODULE__, Queue, :update_order_in_queue, [{floor, :cab, :no_order}])
  end

  def update_order_in_queue(queue, order) do
    {floor, order_type, _order_here?} = order
    orders_at_floor = Enum.at(queue, floor)
    orders_at_floor_updated = List.replace_at(orders_at_floor, order_type_to_queue_index(order_type), order)
    List.replace_at(queue, floor, orders_at_floor_updated)
  end



  # Boolean checks
  
  def order_compatible_with_direction_at_floor?(floor, compatible_order_type) do
    active_orders_at_floor = get_all_active_orders_at_floor(floor)
    ({floor, compatible_order_type, :order} in active_orders_at_floor) or ({floor, :cab, :order} in active_orders_at_floor)
  end

  def active_orders_at_floor?(floor) do
    get_all_active_orders_at_floor(floor) != []
  end

  def active_orders_below_floor?(floor) do
    if floor == Constants.bottom_floor do
      false
    else
      active_orders_at_floor?(floor - 1) or active_orders_below_floor?(floor - 1)
    end
  end

  def active_orders_above_floor?(floor) do
    if floor == Constants.top_floor do
      false
    else
      active_orders_at_floor?(floor + 1) or active_orders_above_floor?(floor + 1)
    end
  end
  

  
  # Helper functions

  def get_all_active_orders_at_floor(floor) do
    orders_at_floor = Agent.get(__MODULE__, fn queue -> Enum.at(queue, floor) end)
    Enum.filter(orders_at_floor, fn order ->
      case order do
        {_floor, _order_type, :order} -> true
        _ -> false
      end
    end)
  end

  def order_type_to_queue_index(order_type) do
    case order_type do
      :hall_up -> 0
      :hall_down -> 1
      :cab -> 2
      _ -> :not_a_order_type
    end
  end

end
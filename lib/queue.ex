defmodule Queue do  # TODO: Gå gjennom og fjern alle unødvendige funksjone
  @moduledoc """
  Agent which stores and deals with accessing the queue.
  """
  use Agent


  # Starting the queue

  def start_link do
    {:ok, agent} = Agent.start_link(Queue, :generate_empty_queue, [], name: __MODULE__)
  end
  """ Fails for some (no) discernible reason
  def start_link(initial_queue) do
    {:ok, agent} = Agent.start_link(fn -> initial_queue end, name: __MODULE__)
  end
  """

  def generate_empty_queue do
    Enum.map(0..Constants.number_of_floors, fn floor -> [{floor, :hall_up, :no_order}, {floor, :hall_down, :no_order}, {floor, :cab, :no_order}] end)
  end


  # Accessing the queue

  def get do
    Agent.get(__MODULE__, fn queue -> queue end)
  end

  def add_order(order) do
    Agent.update(__MODULE__, __MODULE__, :update_order_in_queue, [order])
    # Turn on light here?
  end

  def remove_all_orders_to_floor(floor) do
    Agent.update(__MODULE__, Queue, :update_order_in_queue, [{floor, :hall_up, :no_order}])
    Agent.update(__MODULE__, Queue, :update_order_in_queue, [{floor, :hall_down, :no_order}])
    Agent.update(__MODULE__, Queue, :update_order_in_queue, [{floor, :cab, :no_order}])
  end

  def update_order_in_queue(queue, order) do
    {floor, order_type, order_here?} = order
    orders_at_floor = Enum.at(queue, floor)
    orders_at_floor_updated = List.replace_at(orders_at_floor, order_type_to_queue_index(order_type), order)
    List.replace_at(queue, floor, orders_at_floor_updated)
  end

  """
  def update_whole_queue(new_queue) do
    Agent.update(a_queue, fn queue -> new_queue end)
  end
  """

  def order_at_floor?(floor) do
    orders_at_floor = Agent.get(__MODULE__, fn queue -> Enum.at(queue, floor) end)
    ({floor, :hall_up, :order} in orders_at_floor) or ({floor, :hall_down, :order} in orders_at_floor) or ({floor, :cab, :order} in orders_at_floor)
  end

  def get_all_active_orders_at_floor(a_queue, floor) do
    orders_at_floor = Agent.get(a_queue, fn queue -> Enum.at(queue, floor) end)
    Enum.filter(orders_at_floor, fn order ->
      case order do
        {floor, _order_type, :order} -> true
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

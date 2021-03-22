defmodule DriverFSM do
  @moduledoc """
  Server for implementing FSM controlling actions of the elevator, driving, stopping and opening of doors.
  """

  use GenServer

  # Initialization of FSM

  def start_link(_opts) do # Options?
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Actuator.change_direction(:down)
    pid = Task.async(__MODULE__, :loop_until_at_a_floor, [])
    Task.await(pid)
    Actuator.change_direction(:stop)

    # Exit init state
    {floor, _dir} = Position.get
    cond do
      Queue.get_all_active_orders_above(floor, []) != [] ->
        Actuator.change_direction(:up)
        {:ok, :driving_up}

      Queue.get_all_active_orders_below(floor, []) != [] ->
        Actuator.change_direction(:down)
        {:ok, :driving_down}

      Queue.get_all_active_orders_at_floor(floor) != [] ->
        Actuator.open_door
        Queue.remove_all_orders_to_floor(floor)
        {:ok, :queue_empty}

      true ->
        {:ok, :queue_empty}
    end
  end


  # Events when state == :queue_empty

  def notify_queue_updated(order) do
    GenServer.cast(__MODULE__, {:new_order, order})
  end
  @impl true
  def handle_cast({:new_order, order}, :queue_empty) do
    {floor, _direction} = Position.get
    {order_floor, _order_type, _order_here} = order

    diff = calculate_difference_in_floor(order_floor, floor)
    cond do
      diff > 0 ->
        Actuator.change_direction(:up)
        {:ok, :driving_up}

      diff < 0 ->
        Actuator.change_direction(:down)
        {:ok, :driving_down}

      diff == 0 ->
        Actuator.open_door
        Queue.remove_all_orders_to_floor(floor)
        {:ok, :queue_empty}

      :unknown_diff ->
        Actuator.change_direction(:down)
        {:ok, :driving_down}
    end
  end

  def notify_position_updated(new_position) do
    GenServer.cast(__MODULE__, {:updated_position, new_position})
  end

  # Events when state == :driving_up

  @impl true
  def handle_cast({:updated_position, new_position}, :driving_up) do
    {new_floor, _new_direction} = new_position
    if Queue.order_compatible_with_direction_at_floor?(new_floor, :hall_up) do
      Actuator.change_direction(:stop)
      Actuator.open_door
      Queue.remove_all_orders_to_floor(new_floor)
    end

    cond do
      Queue.worst_order_in_direction(:up) != [] ->
        Actuator.change_direction(:up)
        {:ok, :driving_up}
      
      Queue.worst_order_in_direction(:down) != [] ->
        Actuator.change_direction(:down)
        {:ok, :driving_down}

      true -> # Queue empty
        {:ok, :queue_empty}
    end
  end


  # Events when state == :driving_down

  @impl true
  def handle_cast({:updated_position, new_position}, :driving_down) do
    {new_floor, _new_direction} = new_position
    if Queue.order_compatible_with_direction_at_floor?(new_floor, :hall_down) do
      Actuator.change_direction(:stop)
      Actuator.open_door
      Queue.remove_all_orders_to_floor(new_floor)
    end

    cond do
      Queue.worst_order_in_direction(:down) != [] ->
        Actuator.change_direction(:down)
        {:ok, :driving_down}
      
      Queue.worst_order_in_direction(:up) != [] ->
        Actuator.change_direction(:up)
        {:ok, :driving_up}

      true -> # Queue empty
        {:ok, :queue_empty}
    end
  end

  

  defp calculate_difference_in_floor(_order_floor, :unknown_floor) do
    :unknown_diff
  end
  defp calculate_difference_in_floor(order_floor, floor) do
    order_floor - floor
  end

  def loop_until_at_a_floor() do
    Process.sleep(Constants.driver_wait_loop_sleep_time)
    case Position.at_a_floor? do
      false -> loop_until_at_a_floor()
      true -> :ok
    end
  end
end

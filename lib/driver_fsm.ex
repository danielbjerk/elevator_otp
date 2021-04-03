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

    {:ok, :driving_down}
  end


  # Events when state == :queue_empty

  def handle_cast({:updated_floor, _new_floor}, :queue_empty) do
    Actuator.change_direction(:stop)
    {:noreply, :queue_empty}
  end

  # TODO: functionality for periodically checking if queue is still empty, incase notify_queue_updated-call is lost
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
        {:noreply, :driving_up}

      diff < 0 ->
        Actuator.change_direction(:down)
        {:noreply, :driving_down}

      diff == 0 ->
        Actuator.open_door
        Queue.remove_all_orders_to_floor(floor)
        {:noreply, :queue_empty}

      :unknown_diff ->
        Actuator.change_direction(:down)
        {:noreply, :driving_down}
    end
  end


  def notify_floor_updated(new_floor) do
    GenServer.cast(__MODULE__, {:updated_floor, new_floor})
  end

  # Events when state == :driving_up

  @impl true
  def handle_cast({:updated_floor, new_floor}, :driving_up) do
    if Queue.order_compatible_with_direction_at_floor?(new_floor, :hall_up) do
      Actuator.change_direction(:stop)
      Actuator.open_door
      Queue.remove_all_orders_to_floor(new_floor)
    end

    cond do # now we check for orders above and potentially attempt to move o.o.b if floor = number_of_floors -> FIX
      Queue.active_orders_above_floor?(new_floor) ->
        Actuator.change_direction(:up)
        {:noreply, :driving_up}

      Queue.active_orders_below_floor?(new_floor) ->
        Actuator.change_direction(:down)
        {:noreply, :driving_down}

      true -> # Queue empty
        {:noreply, :queue_empty}
    end
  end


  # Events when state == :driving_down

  @impl true
  def handle_cast({:updated_floor, new_floor}, :driving_down) do
    if Queue.order_compatible_with_direction_at_floor?(new_floor, :hall_down) do
      Actuator.change_direction(:stop)
      Actuator.open_door
      Queue.remove_all_orders_to_floor(new_floor)
    end

    cond do
      Queue.active_orders_below_floor?(new_floor) ->
        Actuator.change_direction(:down)
        {:noreply, :driving_down}

        Queue.active_orders_above_floor?(new_floor) ->  # Now the elevator will prefer to handle orders pick up 2d -> pick up 10000u -> deliver 2d. instead of taking 2d first
        Actuator.change_direction(:up)
        {:noreply, :driving_up}

      true -> # Queue empty
        {:noreply, :queue_empty}
    end
  end


  # Events which aren't to be acted on

  @impl true
  def handle_cast({:new_order, _order}, driving_dir) do
    {:noreply, driving_dir}
  end


  # Helper functions

  defp calculate_difference_in_floor(_order_floor, :unknown_floor) do
    :unknown_diff
  end
  defp calculate_difference_in_floor(order_floor, floor) do
    order_floor - floor
  end

  def loop_until_at_a_floor() do
    Process.sleep(Constants.driver_wait_loop_sleep_time)
    cond do
      not Position.at_a_floor? -> loop_until_at_a_floor()
      true -> :ok
    end
  end
end

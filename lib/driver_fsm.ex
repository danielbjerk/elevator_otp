defmodule DriverFSM do
  @moduledoc """
  Server for implementing FSM controlling actions of the elevator; driving, stopping and opening of doors.
  """

  use GenServer

  # Initialization of FSM

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    if (Position.at_a_floor?) do
      {:ok, :queue_empty}
    else
      Actuator.change_direction(:down)
      {:ok, :driving_down}
    end
  end


  
  # Events when state == :queue_empty

  def handle_cast({:updated_floor, _new_floor}, :queue_empty) do
    Actuator.change_direction(:stop)
    {:noreply, :queue_empty}
  end

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
        :ok = serve_all_orders_to_floor(floor)
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
    if Queue.order_compatible_with_direction_at_floor?(new_floor, :hall_up), do: :ok = serve_all_orders_to_floor(new_floor)

    if Queue.active_orders_above_floor?(new_floor) do
      Actuator.change_direction(:up)
      {:noreply, :driving_up}
    else
      if Queue.active_orders_at_floor?(new_floor), do: :ok = serve_all_orders_to_floor(new_floor)

      if Queue.active_orders_below_floor?(new_floor) do
        Actuator.change_direction(:down)
        {:noreply, :driving_down}
      else
        Actuator.change_direction(:stop)
        {:noreply, :queue_empty}
      end
    end
  end



  # Events when state == :driving_down

  @impl true
  def handle_cast({:updated_floor, new_floor}, :driving_down) do
    if Queue.order_compatible_with_direction_at_floor?(new_floor, :hall_down), do: :ok = serve_all_orders_to_floor(new_floor)

    if Queue.active_orders_below_floor?(new_floor) do
      Actuator.change_direction(:down)
      {:noreply, :driving_down}
    else
      if Queue.active_orders_at_floor?(new_floor), do: :ok = serve_all_orders_to_floor(new_floor)

      if Queue.active_orders_above_floor?(new_floor) do
        Actuator.change_direction(:up)
        {:noreply, :driving_up}
      else
        Actuator.change_direction(:stop)
        {:noreply, :queue_empty}
      end
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

  def serve_all_orders_to_floor(floor) do
    # This funciton guarantees that we only ever open the door if the elevator is at a floor and at a standstill
    # Expected output of :ok when all's good
    if is_integer(floor) do
      Actuator.change_direction(:stop)
      Actuator.open_door
      :ok = Queue.remove_all_orders_to_floor(floor)
      Lights.turn_off_all_at_floor(floor)
      Peer.notify_orders_served(floor)
    else
      {:error, :invalid_floor_for_open_door}
    end
  end
end

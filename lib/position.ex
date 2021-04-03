defmodule Position do
  @moduledoc """
  Agent which stores the elevators position.
  Position is tuple on the form {floor, direction}.
  """
  use Agent

  def start_link(_opts) do
    {:ok, _agent} = Agent.start_link(fn -> {:unknown_floor, :unknown_direction} end, name: __MODULE__)
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end

  def at_a_floor?() do
    {floor, _direction} = Position.get
    is_integer(floor)
  end

  def update(new_floor_or_direction) do
    Agent.update(__MODULE__, __MODULE__, :calculate_update, [new_floor_or_direction])
    if is_integer(new_floor_or_direction) do 
      {floor, direction} = Position.get
      DriverFSM.notify_floor_updated(floor)
    end
    #DriverFSM.notify_floor_updated(get)
  end

  def calculate_update(old_position, update) do
    {old_floor, old_direction} = old_position
    case update do
      direction when direction in [:up, :down, :stop] ->
        {old_floor, direction}

      floor when is_number(floor) ->
        {floor, old_direction}

      :between_floors ->
        case old_direction do
          :up ->
            {add_to_floor(old_floor, 0.5), old_direction}
          :down ->
            {add_to_floor(old_floor, -0.5), old_direction}
          :stop ->
            {old_floor, old_direction}
        end
    end
  end
  def add_to_floor(:unknown_floor, _num) do
    :unknown_floor
  end 
  def add_to_floor(floor, num) do
    floor + num
  end
end

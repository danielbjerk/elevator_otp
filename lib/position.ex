defmodule Position do
  @moduledoc """
  Agent which stores the elevators position.
  Position is tuple on the form {floor, direction}.
  """
  use Agent

  def start_link do
    {:ok, agent} = Agent.start_link(fn {:unknown_floor, :unknown_direction} -> {:unknown_floor, :unknown_direction} end, name: __MODULE__)
  end

  def get() do
    Agent.get(__MODULE__, & &1)
  end

  def at_a_floor?() do
    {floor, _direction} = Position.get
    floor !== :between_floors
  end

  def update(update) do
    Agent.update(__MODULE__, __MODULE__, :calculate_update, [update])
  end

  def calculate_update(old_position, update) do
    {old_floor, old_direction} = old_position
    case update do
      direction when direction in [:up, :down, :stop] ->
        {old_floor, direction}

      floor when is_number(floor) ->
        {floor, old_direction}

      :between_floors ->
        case old_direction do    # Isn't it enough to case against old direction?
          :up ->
            {old_floor + 0.5, old_direction}
          :down ->
            {old_floor - 0.5, old_direction}
          :stop ->
            {old_floor, old_direction}
        end
    end
  end
end

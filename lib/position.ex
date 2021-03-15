defmodule Position do
  @moduledoc """
  Agent which stores the elevators position.
  """
  use Agent

  def start_link do
    {:ok, agent} = Agent.start_link(fn {:unknown_floor, :unknown_direction} -> {:unknown_floor, :unknown_direction} end, name: __MODULE__)
  end

  def update_floor(update) do
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
        case {old_direction, old_floor} do
          {:up, old_floor} ->
            {old_floor + 0.5, old_direction}

          {:down, old_floor} ->
            {old_floor - 0.5, old_direction}
          {:stop, old_floor} ->
            {old_floor, old_direction}
        end
    end
end

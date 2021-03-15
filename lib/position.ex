defmodule Position do
  @moduledoc """
  Agent which stores the elevators position.
  """
  use Agent

  def start_link do
    {:ok, agent} = Agent.start_link(fn -> {:unknown_floor, :unknown_direction} end, name: __MODULE__)
  end
end

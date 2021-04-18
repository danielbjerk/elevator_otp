# ElevatorOtp

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elevator_otp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elevator_otp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elevator_otp](https://hexdocs.pm/elevator_otp).

Elevator number n is started by first running the simulator with argument "--port (15657+n)", with the first elevator being n=0.
Then the project may be compiled and ran and started with ElevatorOTP.start(n)

## Code Quality Standard
See below for standard code needs to uphold

- Modules are named in CamelCase, everything else is snake_case (required by Elixir)
- Functions or variables in modules are NOT prepended like modulename_function_name

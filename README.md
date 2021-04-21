Elevator Project
================

# ElevatorOtp

Elevator-control and fault-handling software, heavily relying on Elixir programming principles like fail fast and the OTP-framework


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


## Running the program
After installation, the static IP of each elevator's computer must be stored in `constants.ex`.

Elevator number n is started by first running the simulator in `/Simulator/` by writing
`./SimElevatorServer --port (15657+n)`
with the first elevator taking number n = 0.

Then the project may be compiled with `iex -S mix` and ran and started by running the function `ElevatorOTP.start(n, 15657 + y, debug (true/false))`
where `y` is equal to `n` if running all simulators on the same PC or `0` elsewise.


Unspecified behaviour
---------------------

The elevator will take any order in ptp-mode as long as it is able to confirm that it's peers have logged said order. In single-elevator mode the elevator will take every order.

   
Assumptions
---------------------

The only assumption made in this implementation (beyond the base assumptions given) is the use of static IP for each elevator's computer. We feel this is a natural assumption, but concede that broadcasting each elevator's IP over UDP should be possible to implement even though we were unable to do so.

   
Additional resources
--------------------

Go to [the project resources repository](https://github.com/TTK4145/Project-resources) to find more resources for doing the project. This information is not required for the project, and is therefore maintained separately.

See [Testing from home](/testing_from_home.md) document on how to test with unreliable networking on a single computer.


## Code Quality Standard
See below for standard code needs to uphold

- Modules are named in CamelCase, everything else is snake_case (required by Elixir)
- Functions or variables in modules are NOT prepended like modulename_function_name

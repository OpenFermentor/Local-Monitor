# MonitorBackend
This repo contains the code related to the local backend that is in charge of running and monitoring the rountine run on the fermentor.
This server will run locally inside the terminal that will be directly connected to the micro-controller.
It will:
  * Send and receive data and instructions to the micro-controller via serial port.
  * Control the temperature on the bath via serial port.
  * Expose a REST API for the Monitoring UI.
  * Send live updates to the Monitoring UI via web-sockets.

# API docs
For more detailed usage, check out it [here](https://openfermentor.github.io/MonitorBackend/)

# Instalation
To run the MonitorBackend follow these steps:
  1. Clone the repo.
  2. Installs the dependencies using `mix deps.get`
  3. Create the database running `mix ecto.create` you need `PostgreSQL` installed and running on your machine.
  4. Run the server using `mix phoenix.serve`

# Dependencies
The following dependencies are used on this project:
  * `Elixir 1.4.2`.
  * `Phoenix 1.2` as our web framework.
  * `Credo` for style code checking.
  * `Faker` for faking data for testing.
  * `Nerves.UART` for communication via serial port with external devices.

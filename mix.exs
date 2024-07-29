defmodule ControlPacket.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_packet,
      version: "1.1.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "ControlPacket",
      description: "MQTT 5 packet decoder and encoder",
      source_url: "https://github.com/TimisRobert/control_packet"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/TimisRobert/control_packet"}
    ]
  end
end

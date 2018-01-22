defmodule ExSimpleAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exsimpleauth,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # mod: {ExSimpleAuth.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jwt_claims, "~> 0.0"},
      {:json_web_token, "~> 0.2"},
      {:ex_doc, "~> 0.18.1", only: :dev},
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 0.3", only: [:dev, :test]},
    ]
  end
end

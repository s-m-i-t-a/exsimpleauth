defmodule ExSimpleAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exsimpleauth,
      version: "1.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      description: "A simple authentication library.",
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
      # mod: {ExSimpleAuth.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jwt_claims, "~> 0.0"},
      {:json_web_token, "~> 0.2"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:plug, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:result, "~> 1.1"}
    ]
  end

  defp package do
    [
      maintainers: [
        "Jindrich K. Smitka <smitka.j@gmail.com>"
      ],
      licenses: ["BSD"],
      links: %{
        "GitHub" => "https://github.com/s-m-i-t-a/exsimpleauth"
      }
    ]
  end
end

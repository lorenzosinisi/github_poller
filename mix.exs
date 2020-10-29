defmodule GithubPoller.MixProject do
  use Mix.Project

  def project do
    [
      app: :github_poller,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GithubPoller.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.5"},
      {:jason, "~> 1.2"}
    ]
  end
end

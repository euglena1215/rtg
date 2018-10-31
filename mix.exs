defmodule Rtg.Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      apps_path: "apps",
      deps: deps(),
      dialyzer: [
        flags: [:no_undefined_callbacks],
        ignore_warnings: "dialyzer.ignore-warnings",
        remove_defaults: [:unknown]
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp aliases do
    [
      clean: deftask("clean", "run clean"),
      compile: deftask("compile", "run compile"),
      format: deftask("format", "run format"),
      outdated: deftask("hex.outdated", "run outdated"),
      setup: deftask("deps.get", "install")
    ]
  end

  defp deftask(mix_task, npm_task) do
    fn _ ->
      Mix.Task.run(mix_task)

      "apps/rtg_web"
      |> Path.expand(__DIR__)
      |> File.cd!(fn -> Mix.Shell.IO.cmd("npm #{npm_task}") end)
    end
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [
      {:inner_cotton, "~> 0.3", only: [:dev, :test]}
    ]
  end
end

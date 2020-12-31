defmodule Txpost.MixProject do
  use Mix.Project

  def project do
    [
      app: :txpost,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Txpost",
      description: "TODO",
      source_url: "https://github.com/libitx/txpost",
      docs: [
        main: "Txpost",
        extras: [
          "brfc-specs/cbor-tx-envelope.md",
          "brfc-specs/cbor-tx-payload.md"
        ],
        groups_for_extras: [
          BRFCs: ~r/brfc-specs\//,
        ],
        groups_for_modules: [
          Plugs: [
            Txpost.Plug,
            Txpost.Plug.EnvelopeRequired,
            Txpost.Plug.PayloadDeserializer
          ],
          Parsers: [
            Txpost.Parsers.CBOR
          ]
        ]
      ],
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
      {:cbor, "~> 1.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:plug, "~> 1.11"}
    ]
  end
end

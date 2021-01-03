defmodule Txpost.MixProject do
  use Mix.Project

  def project do
    [
      app: :txpost,
      version: "0.1.0-beta.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Txpost",
      description: "Receive Bitcoin transactions over HTTP in a concise and efficient binary serialisation format.",
      source_url: "https://github.com/libitx/txpost",
      docs: [
        main: "Txpost",
        extras: [
          "brfc-specs/cbor-tx-payload.md",
          "brfc-specs/cbor-tx-envelope.md"
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
      package: [
        name: "txpost",
        files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
        licenses: ["Apache-2.0"],
        links: %{
          "GitHub" => "https://github.com/libitx/txpost"
        }
      ]
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

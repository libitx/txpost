defmodule Txpost do
  @moduledoc """
  ![License](https://img.shields.io/github/license/libitx/txpost?color=informational)

  Receive Bitcoin transactions over HTTP in a concise and efficient binary
  serialisation format.

  Txpost implements a standard for encoding and decoding Bitcoin transactions
  and other data in a concise binary format using [CBOR](https://cbor.io). A
  number of modules following the Plug specification can easily be slotted in
  your Phoenix or Plug based application's pipeline. An optional Router module
  is available, allowing you to implement routing logic for different types of
  transactions from a single endpoint.

  * Concise and efficient binary data serialisation format
  * Send transactions over HTTP - faster and cheaper
  * Simple and flexible schema for transferring Bitcoin transations with arbitrary data parameters
  * Send single or multiple transactions in one request
  * Sign and verify data payloads with ECDSA signatures

  ### BRFC specifications

  Txpost is an implementation of the following BRFC specifications. They
  describe a standard for serialising Bitcoin transactions and associated
  parameters, along with arbitrary meta data, in a concise binary format using
  CBOR:

  * BRFC `c9a2975b3d19` - [CBOR Tx Payload specification](cbor-tx-payload.md)
  * BRFC `5b82a2ed7b16` - [CBOR Tx Envelope specification](cbor-tx-envelope.md)

  ## Installation

  The package can be installed by adding `txpost` to your list of dependencies
  in `mix.exs`.

      def deps do
        [
          {:txpost, "~> 0.1"}
        ]
      end

  Add `Txpost.Parsers.CBOR` to your endpoint's list of parsers.

      plug Plug.Parsers,
        parsers: [
          :json,
          Txpost.Parsers.CBOR
        ]

  Finally create any routes needed to handle transaction requests and add
  `Txpost.Plug` to the plug pipeline. For example, adding a route to a Phoenix
  router:

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router

        pipeline :tx_api do
          plug :accepts, ["cbor"]
          plug Txpost.Plug
        end

        scope "/tx" do
          pipe_through :tx_api
          post "/create", MyAppWeb.TxController, :create
        end
      end

  ## Transaction routing

  The example above creates a single route passing all transactions to the same
  controller. You could create many routes for different transactions but in
  some applications it may be desirable to advertise a single endpoint to
  receive different types of transactions, each handled by different
  controllers. In this case `Txpost.Router` can be used to route transactions to
  different controllers, using any logic you need.

  A tx router is a module that implements the `c:Txpost.Router.handle_tx/2`
  callback.

      defmodule MyApp.TxRouter do
        use Txpost.Router

        def handle_tx(conn, _params) do
          case get_req_meta(conn) do
            %{"type" => "article"} -> ArticleController.call(conn, :create)
            %{"type" => "image"} -> ImageController.call(conn, :create)
          end
        end
      end

  For more details, see `Txpost.Router`.
  """
end

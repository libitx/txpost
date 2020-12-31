# Txpost

Receive Bitcoin transactions over HTTP for Plug and Phoenix based applications.

The following BRFCs describe a standard for serialising Bitcoin transactions and associated parameters, along with any arbitrary meta data, in a concise binary format using CBOR:

* BRFC #TODO - Todo
* BRFC #TODO - Todo

Txpost implements both BRFCs in modules following the Plug specification. In addition, Txpost provides a Router module so you can advertise a single API endpoint for recieving transactions and build your own logic for routing transactions to different controllers.

## Installation

The package can be installed by adding `txpost` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:txpost, "~> 0.1"}
  ]
end
```

Add `Txpost.Parsers.CBOR` to your endpoint's list of parsers.

```elixir
plug Plug.Parsers,
  parsers: [
    :json,
    Txpost.Parsers.CBOR
  ]
```

Finally create any routes needed to handle transaction requests and add `Txpost.Plug` to the plug pipeline. For example, adding a route to a Phoenix router:

```elixir
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
```

For detailed examples, refer to the [full documentation](https://hexdocs.pm/txpost).

## Transaction routing

The example above creates a single route passing all transactions to the same controller. You could create many routes for different transactions but in some applications it may be desirable to advertise a single endpoint to receive different types of transactions, each handled by different controllers. In this case `Txpost.Router` can be used to route transactions to different controllers, using any logic you need.

A tx router is a module that implements the `Txpost.Router.handle_tx/2` callback.

```elixir
defmodule MyApp.TxRouter do
  use Txpost.Router

  def handle_tx(conn, _params) do
    case get_req_meta(conn) do
      %{"type" => "article"} -> ArticleController.call(conn, :create)
      %{"type" => "image"} -> ImageController.call(conn, :create)
    end
  end
end
```

For more details, refer to the [full documentation](https://hexdocs.pm/txpost).

## License

Txbox is open source and released under the [Apache-2 License](https://github.com/libitx/txpost/blob/master/LICENSE.md).

© Copyright 2021 Chronos Labs Ltd.
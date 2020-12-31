defmodule Txpost.Router do
  @moduledoc """
  Very simple router behaviour so your can advertise a single route to handle
  all incoming transactions.

  Define a module that implements the `c:handle_tx/2` callback. For example:

      defmodule MyApp.TxRouter do
        use Txpost.Router

        def handle_tx(conn, _params) do
          case get_req_meta(conn) do
            %{"type" => "article"} -> ArticleController.call(conn, :create)
            %{"type" => "image"} -> ImageController.call(conn, :create)
          end
        end
      end

  The `c:handle_tx/2` callback gives you access to the connection and request
  parameters, meaning you can use any part of the request, including headers,
  request meta data or the raw transaction itself, and call the appropriate
  action to handle the request.

  As the router is a plug, you can add a single route to your main router to
  handle all incoming transactions. For example, a Phoenix router
  implementation may look like:

      defmodule MyApp.Router do
        use MyApp, :router

        pipeline :tx_api do
          plug :accepts, ["cbor"]
          plug Txpost.Plug
        end

        scope "/tx" do
          pipe_through :tx_api
          post "/", MyApp.TxRouter, []
        end
      end

  Alternatively, implemented using a Plug router may look like:

      defmodule MyApp.Router do
        use Plug.Router

        plug :match
        plug Plug.Parsers, parsers: [Txpost.Parsers.CBOR]
        plug Txpost.Plug
        plug :dispatch

        post "/tx", to: MyApp.TxRouter
      end
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Plug.Conn
      import Txpost.Router
      @behaviour Plug

      @impl true
      def init(opts), do: opts

      @impl true
      def call(conn, _opts), do: handle_tx(conn, conn.params)
    end
  end


  @doc """
  Invoked to handle incoming requests.

  Function recieves the connection and request parameters which will include the
  raw transaction.

  Any logic can be used the determine the correct route, and call any "action"
  function that adheres to the Plug specification and returns the connection.

  ## Examples

  Use the request meta data to route the request:

      def handle_tx(conn, params) do
        case get_req_meta(conn) do
          %{"type" => "article"} -> ArticleController.create(conn, params)
          %{"type" => "image"} -> ImageController.create(conn, params)
        end
      end

  Use Shapeshifter to decode the raw transaction.

      def handle_tx(conn, %{"rawtx" => rawtx}) do
        [output | _] = rawtx
        |> Shapeshifter.to_txo
        |> Map.get("out")

        case output do
          %{"s3" => "article"} -> ArticleController.call(conn, :create)
          %{"s3" => "image"} -> ImageController.call(conn, :create)
        end
      end
  """
  @callback handle_tx(conn :: Plug.Conn.t, params :: map | list(map)) :: Plug.Conn.t


  @doc """
  Returns the request payload meta data.
  """
  @spec get_req_meta(Plug.Conn.t) :: map | nil
  def get_req_meta(%{private: %{txpost_payload: payload}} = _conn), do: payload.meta
  def get_req_meta(%{params: %{"meta" => meta}}), do: meta
  def get_req_meta(_conn), do: nil

end

defmodule Txpost.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @rawtx <<1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 >>

  defmodule TestController do
    def a(conn, _), do: Plug.Conn.resp(conn, 200, "A")
    def b(conn, _), do: Plug.Conn.resp(conn, 200, "B")
  end

  defmodule TestRouter do
    use Txpost.Router

    def handle_tx(conn, params) do
      case get_req_meta(conn) do
        %{"path" => "a"} -> TestController.a(conn, params)
        %{"path" => "b"} -> TestController.b(conn, params)
      end
    end
  end

  def cbor_conn(body, content_type \\ "application/cbor") do
    put_req_header(conn(:post, "/", body), "content-type", content_type)
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Txpost.Parsers.CBOR])
    conn
    |> plug(Plug.Parsers, opts)
    |> plug(Txpost.Plug)
    |> plug(TestRouter)
  end

  def plug(conn, mod, opts \\ []) do
    apply(mod, :call, [conn, apply(mod, :init, [opts])])
  end

  setup do
    {:ok, p1} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx, "foo" => "bar"}, meta: %{"path" => "a"}})
    {:ok, p2} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx, "foo" => "bar"}, meta: %{"path" => "b"}})
    {:ok, e1} = Txpost.Envelope.build(payload: p1)
    {:ok, e2} = Txpost.Envelope.build(payload: p2)
    %{e1: e1, e2: e2}
  end

  test "routes to correct action based on meta object", %{e1: e1, e2: e2} do
    assert %{resp_body: "A"} = cbor_conn(Txpost.Envelope.encode(e1)) |> parse
    assert %{resp_body: "B"} = cbor_conn(Txpost.Envelope.encode(e2)) |> parse
  end

end

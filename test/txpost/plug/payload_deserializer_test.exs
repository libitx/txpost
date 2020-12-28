defmodule Txpost.Plug.PayloadDeserializerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @rawtx <<1,0,0,0,0,0,0,0,0,0>>

  def cbor_conn(body, content_type \\ "application/cbor") do
    put_req_header(conn(:post, "/", body), "content-type", content_type)
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Txpost.Parsers.CBOR])
    conn
    |> plug(Plug.Parsers, opts)
    |> plug(Txpost.Plug.PayloadDeserializer, opts)
  end

  def plug(conn, mod, opts \\ []) do
    apply(mod, :call, [conn, apply(mod, :init, [opts])])
  end

  test "should parse and flatten the CBOR payload" do
    {:ok, payload} = Txpost.Payload.build(%{
      data: %{"rawtx" => @rawtx, "foo" => "bar"},
      meta: %{"a" => 1}
    })

    conn = payload
    |> Txpost.Payload.encode
    |> cbor_conn
    |> parse

    assert %{"foo" => "bar", "meta" => %{"a" => 1}, "rawtx" => @rawtx} = conn.params
  end

  test "should parse and flatten the CBOR payload when data is an array" do
    {:ok, payload} = Txpost.Payload.build(%{
      data: [%{"rawtx" => @rawtx, "foo" => "a"}, %{"rawtx" => @rawtx, "foo" => "b"}],
      meta: %{"a" => 1}
    })

    conn = payload
    |> Txpost.Payload.encode
    |> cbor_conn
    |> parse

    assert [
      %{"rawtx" => @rawtx, "foo" => "a"},
      %{"rawtx" => @rawtx, "foo" => "b"}
    ] = conn.params
  end

end

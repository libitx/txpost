defmodule Txpost.Parsers.CBORTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @rawtx <<1,0,0,0,0,0,0,0,0,0>>
  @cbor_payload <<161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  @cbor_envelope <<161, 103, 112, 97, 121, 108, 111, 97, 100, 114, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

  def cbor_conn(body, content_type \\ "application/cbor") do
    put_req_header(conn(:post, "/", body), "content-type", content_type)
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Txpost.Parsers.CBOR])
    conn
    |> plug(Plug.Parsers, opts)
  end

  def plug(conn, mod, opts \\ []) do
    apply(mod, :call, [conn, apply(mod, :init, [opts])])
  end


  test "should parse the CBOR payload" do
    conn = cbor_conn(@cbor_payload) |> parse
    assert conn.params["rawtx"] == @rawtx
  end

  test "should parse the CBOR envelope" do
    conn = cbor_conn(@cbor_envelope) |> parse
    assert conn.params["payload"] == @cbor_payload
  end

  test "parses the request body when it is an array" do
    conn = CBOR.encode([1, 2, 3]) |> cbor_conn |> parse
    assert conn.params["_cbor"] == [1, 2, 3]
  end

  test "parses the request body when it is a scalar" do
    conn = CBOR.encode("str") |> cbor_conn |> parse
    assert conn.params["_cbor"] == "str"
  end

  test "parses the request body when it is a number" do
    conn = CBOR.encode(1) |> cbor_conn |> parse
    assert conn.params["_cbor"] == 1
  end

  test "parses the request body when it is a boolean" do
    conn = CBOR.encode(false) |> cbor_conn |> parse
    assert conn.params["_cbor"] == false
  end

  test "parses the request body when it is null" do
    conn = nil |> cbor_conn |> parse
    assert conn.params == %{}
  end

  test "parses cbor-parseable content types" do
    conn = CBOR.encode(%{id: 1}) |> cbor_conn(("application/vnd.api+cbor")) |> parse
    assert conn.params["id"] == 1
  end

end

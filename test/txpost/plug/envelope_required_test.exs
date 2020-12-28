defmodule Txpost.Plug.EnvelopeRequiredTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @rawtx <<1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 >>
  @cbor_payload <<
    161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0>>
  @cbor_envelope <<
    162, 103, 112, 97, 121, 108, 111, 97, 100, 120, 24, 161, 100, 100, 97, 116,
    97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    102, 112, 117, 98, 107, 101, 121, 99, 97, 98, 99>>
  @cbor_envelope_signed <<
    162, 103, 112, 97, 121, 108, 111, 97, 100, 120, 24, 161, 100, 100, 97, 116,
    97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    102, 112, 117, 98, 107, 101, 121, 99, 97, 98, 99>>

  def cbor_conn(body, content_type \\ "application/cbor") do
    put_req_header(conn(:post, "/", body), "content-type", content_type)
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Txpost.Parsers.CBOR])
    conn
    |> plug(Plug.Parsers, opts)
    |> plug(Txpost.Plug.EnvelopeRequired, opts)
  end

  def plug(conn, mod, opts \\ []) do
    apply(mod, :call, [conn, apply(mod, :init, [opts])])
  end

  test "should parse the CBOR envelope" do
    conn = cbor_conn(@cbor_envelope) |> parse
    assert get_in(conn.params, ["data", "rawtx"]) == @rawtx
  end

  @tag :pending
  test "should parse a signed CBOR envelope" do
    conn = cbor_conn(@cbor_envelope_signed) |> parse(ensure_signed: true)
    assert get_in(conn.params, ["data", "rawtx"]) == @rawtx
  end

  test "should raise requires signature" do
    assert_raise Txpost.Envelope.InvalidSignatureError, fn ->
      cbor_conn(@cbor_envelope) |> parse(ensure_signed: true)
    end
  end

  test "should raise when invalid CBOR envelope" do
    assert_raise Plug.BadRequestError, fn ->
      cbor_conn(@cbor_payload) |> parse
    end
  end

end

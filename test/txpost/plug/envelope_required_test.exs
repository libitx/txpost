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
    163, 103, 112, 97, 121, 108, 111, 97, 100, 120, 24, 161, 100, 100, 97, 116,
    97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    102, 112, 117, 98, 107, 101, 121, 120, 33, 2, 170, 75, 142, 232, 142, 111,
    76, 138, 31, 212, 197, 4, 20, 227, 157, 8, 252, 150, 79, 61, 83, 205, 99,
    54, 225, 193, 254, 122, 200, 147, 51, 180, 105, 115, 105, 103, 110, 97, 116,
    117, 114, 101, 120, 70, 48, 68, 2, 32, 24, 134, 241, 47, 243, 122, 86, 199,
    199, 220, 173, 209, 38, 189, 238, 84, 197, 20, 218, 193, 190, 35, 88, 95,
    214, 137, 204, 206, 156, 21, 223, 5, 2, 32, 67, 243, 10, 255, 17, 52, 68,
    176, 250, 253, 199, 208, 16, 167, 132, 183, 206, 49, 147, 241, 61, 117, 231,
    254, 197, 52, 109, 45, 247, 78, 210, 62>>


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

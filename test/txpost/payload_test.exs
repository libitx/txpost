defmodule Txpost.PayloadTest do
  use ExUnit.Case, async: true
  doctest Txpost.Payload

  @rawtx <<1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 >>
  @cbor_payload <<
    161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0>>
  @cbor_payload_multi <<
    161, 100, 100, 97, 116, 97, 130, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0>>

  describe "build/1" do
    test "builds payload when params is map" do
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx, "foo" => "bar"}})
      assert payload.data == %{"foo" => "bar", "rawtx" => @rawtx}
    end

    test "builds payload when params is keyword list" do
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(data: %{"rawtx" => @rawtx, "foo" => "bar"})
      assert payload.data == %{"foo" => "bar", "rawtx" => @rawtx}
    end

    test "builds payload when param keys are strings" do
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(%{"data" => %{"rawtx" => @rawtx}})
      assert payload.data == %{"rawtx" => @rawtx}
    end

    test "builds payload when data is array" do
      data = [%{"rawtx" => @rawtx}, %{"rawtx" => @rawtx}]
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(%{"data" => data})
      assert is_list(payload.data)
      assert List.first(payload.data) == %{"rawtx" => @rawtx}
    end

    test "safely ignores other keys" do
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx}, foo: "bar"})
      assert payload.data == %{"rawtx" => @rawtx}
    end

    test "validates params" do
      assert {:error, "Invalid param: data"} = Txpost.Payload.build(%{})
      assert {:error, "Invalid param: data"} = Txpost.Payload.build(%{data: 0})
      assert {:error, "Invalid param: meta"} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx}, meta: 0})
    end
  end


  describe "decode/1" do
    test "decodes valid cbor binary into payload" do
      assert {:ok, payload} = Txpost.Payload.decode(@cbor_payload)
      assert payload.data == %{"rawtx" => @rawtx}
    end

    test "decodes valid cbor binary with data array into payload" do
      assert {:ok, payload} = Txpost.Payload.decode(@cbor_payload_multi)
      assert is_list(payload.data)
      assert List.first(payload.data) == %{"rawtx" => @rawtx}
    end

    test "returns error with invalid cbor payload" do
      assert {:error, "Invalid payload binary"} = Txpost.Payload.decode(<<0,1,2,3>>)
    end
  end


  describe "encode/1" do
    test "encodes payload into CBOR binary" do
      {:ok, payload} = Txpost.Payload.build(data: %{"rawtx" => @rawtx})
      res = Txpost.Payload.encode(payload)
      assert is_binary(res)
      assert res == @cbor_payload
    end
  end


  describe "encode_envelope/1" do
    test "wraps encoded payload into en Envelope struct" do
      {:ok, payload} = Txpost.Payload.build(data: %{"rawtx" => @rawtx})
      assert %Txpost.Envelope{payload: @cbor_payload} = Txpost.Payload.encode_envelope(payload)
    end
  end


  describe "to_map/1" do
    test "returns stringified keys" do
      {:ok, payload} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx, "foo" => "bar"}, meta: %{"a" => 1}})
      assert %{
        "data" => %{"foo" => "bar", "rawtx" => @rawtx},
        "meta" => %{"a" => 1},
      } == Txpost.Payload.to_map(payload)
    end

    test "returns stringified keys with blank maps excluded" do
      {:ok, payload} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx, "foo" => "bar"}})
      assert %{
        "data" => %{"foo" => "bar", "rawtx" => @rawtx}
      } == Txpost.Payload.to_map(payload)
    end
  end

end

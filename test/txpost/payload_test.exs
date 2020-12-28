defmodule Txpost.PayloadTest do
  use ExUnit.Case
  doctest Txpost.Payload

  @rawtx <<1,0,0,0,0,0,0,0,0,0>>
  @cbor_payload <<161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>


  describe "build/1" do
    test "builds struct when params is map" do
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(%{rawtx: @rawtx, data: %{"foo" => "bar"}})
      assert payload.rawtx == @rawtx
      assert payload.data == %{"foo" => "bar"}
    end

    test "builds struct when params is keyword list" do
      assert {:ok, %Txpost.Payload{} = payload} = Txpost.Payload.build(rawtx: @rawtx, data: %{"foo" => "bar"})
      assert payload.rawtx == @rawtx
      assert payload.data == %{"foo" => "bar"}
    end

    test "builds struct when param keys are strings" do
      assert {:ok, %Txpost.Payload{rawtx: @rawtx}} = Txpost.Payload.build(%{"rawtx" => @rawtx})
      assert {:ok, %Txpost.Payload{rawtx: @rawtx}} = Txpost.Payload.build([{"rawtx", @rawtx}])
    end

    test "safely ignores other keys" do
      assert {:ok, %Txpost.Payload{rawtx: @rawtx}} = Txpost.Payload.build(%{rawtx: @rawtx, foo: "bar"})
      assert {:ok, %Txpost.Payload{rawtx: @rawtx}} = Txpost.Payload.build(rawtx: @rawtx, foo: "bar")
    end

    test "validates params" do
      assert {:error, "Invalid param: rawtx"} = Txpost.Payload.build(%{})
      assert {:error, "Invalid param: data"} = Txpost.Payload.build(%{rawtx: @rawtx, data: 0})
      assert {:error, "Invalid param: meta"} = Txpost.Payload.build(%{rawtx: @rawtx, meta: 0})
    end
  end


  describe "decode/1" do
    test "decodes valid cbor binary into payload" do
      assert {:ok, payload} = Txpost.Payload.decode(@cbor_payload)
      assert payload.rawtx == @rawtx
    end

    test "returns error with invalid cbor payload" do
      assert {:error, "Invalid payload binary"} = Txpost.Payload.decode(<<0,1,2,3>>)
    end
  end


  describe "encode/1" do
    test "encodes payload into CBOR binary" do
      {:ok, payload} = Txpost.Payload.build(%{rawtx: @rawtx})
      res = Txpost.Payload.encode(payload)
      assert is_binary(res)
    end
  end


  describe "to_map/2" do
    test "returns stringified keys with nil maps included" do
      {:ok, payload} = Txpost.Payload.build(%{rawtx: @rawtx, data: %{"foo" => "bar"}})
      assert %{
        "data" => %{"foo" => "bar"},
        "meta" => %{},
        "rawtx" => @rawtx
      } == Txpost.Payload.to_map(payload)
    end

    test "returns stringified keys with nil maps excluded" do
      {:ok, payload} = Txpost.Payload.build(%{rawtx: @rawtx})
      assert %{"rawtx" => @rawtx} == Txpost.Payload.to_map(payload, include_nil: false)
    end
  end

end

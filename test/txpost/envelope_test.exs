defmodule Txpost.EnvelopeTest do
  use ExUnit.Case
  doctest Txpost.Envelope

  @payload <<161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  @cbor_envelope <<161, 103, 112, 97, 121, 108, 111, 97, 100, 114, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>


  describe "build/1" do
    test "builds struct when params is map" do
      assert {:ok, %Txpost.Envelope{} = env} = Txpost.Envelope.build(%{payload: @payload, pubkey: "abc"})
      assert env.payload == @payload
      assert env.pubkey == "abc"
    end

    test "builds struct when params is keyword list" do
      assert {:ok, %Txpost.Envelope{} = env} = Txpost.Envelope.build(payload: @payload, pubkey: "abc")
      assert env.payload == @payload
      assert env.pubkey == "abc"
    end

    test "builds struct when param keys are strings" do
      assert {:ok, %Txpost.Envelope{payload: @payload}} = Txpost.Envelope.build(%{"payload" => @payload})
      assert {:ok, %Txpost.Envelope{payload: @payload}} = Txpost.Envelope.build([{"payload", @payload}])
    end

    test "safely ignores other keys" do
      assert {:ok, %Txpost.Envelope{payload: @payload}} = Txpost.Envelope.build(%{payload: @payload, foo: "bar"})
      assert {:ok, %Txpost.Envelope{payload: @payload}} = Txpost.Envelope.build(payload: @payload, foo: "bar")
    end

    test "validates params" do
      assert {:error, "Invalid param: payload"} = Txpost.Envelope.build(%{})
      assert {:error, "Invalid param: pubkey"} = Txpost.Envelope.build(%{payload: @payload, pubkey: 0})
      assert {:error, "Invalid param: signature"} = Txpost.Envelope.build(%{payload: @payload, signature: 0})
    end
  end


  describe "decode/1" do
    test "decodes valid cbor binary into envelope" do
      assert {:ok, env} = Txpost.Envelope.decode(@cbor_envelope)
      assert env.payload == @payload
    end

    test "returns error with invalid cbor envelope" do
      assert {:error, "Invalid payload binary"} = Txpost.Envelope.decode(<<0,1,2,3>>)
    end
  end


  describe "decode_payload/1" do
    test "decodes payload from the envelope" do
      assert {:ok, env} = Txpost.Envelope.decode(@cbor_envelope)
      assert {:ok, %Txpost.Payload{}} = Txpost.Envelope.decode_payload(env)
    end
  end


  describe "encode/1" do
    test "encodes envelope into CBOR binary" do
      {:ok, env} = Txpost.Envelope.build(%{payload: @payload})
      res = Txpost.Envelope.encode(env)
      assert is_binary(res)
    end
  end

end

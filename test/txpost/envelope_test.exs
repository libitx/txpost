defmodule Txpost.EnvelopeTest do
  use ExUnit.Case, async: true
  doctest Txpost.Envelope

  @rawtx <<1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 >>
  @payload <<
    161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0>>
  @cbor_envelope <<
    162, 103, 112, 97, 121, 108, 111, 97, 100, 88, 24, 161, 100, 100, 97, 116,
    97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 102,
    112, 117, 98, 107, 101, 121, 67, 97, 98, 99>>


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

    test "builds struct when payload is struct" do
      {:ok, payload} = Txpost.Payload.build(%{data: %{"rawtx" => @rawtx}})
      assert {:ok, %Txpost.Envelope{} = env} = Txpost.Envelope.build(%{payload: payload})
      assert env.payload == @payload
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


  describe "to_map/1" do
    test "returns stringified keys" do
      {:ok, env} = Txpost.Envelope.build(payload: @payload, pubkey: "abc")
      assert %{"payload" => @payload, "pubkey" => "abc"} == Txpost.Envelope.to_map(env)
    end

    test "returns stringified keys with blank keys excluded" do
      {:ok, env} = Txpost.Envelope.build(payload: @payload)
      assert %{"payload" => @payload} == Txpost.Envelope.to_map(env)
    end
  end


  describe "sign/2" do
    @tag :pending
    test "signs payload and adss signature and pubkey to envelope" do
      {:ok, env} = Txpost.Envelope.build(payload: @payload)
      {:ok, env} = Txpost.Envelope.sign(env, "todo")
      IO.inspect env
    end
  end


  describe "verify/1" do
    setup do
      %{
        pk: <<
          3, 53, 230, 236, 108, 23, 137, 176, 135, 106, 12, 1, 117, 89, 207, 16,
          73, 77, 112, 189, 84, 33, 217, 82, 243, 239, 127, 158, 114, 186, 157,
          47, 237>>,
        pk2: <<
          2, 191, 198, 200, 103, 32, 252, 60, 22, 157, 186, 109, 178, 126, 223,
          217, 233, 196, 171, 116, 165, 101, 14, 35, 161, 247, 225, 153, 162,
          245, 6, 190, 194>>,
        sig: <<
          48, 68, 2, 32, 2, 214, 219, 161, 103, 184, 136, 185, 39, 226, 77, 25, 37,
          119, 139, 238, 192, 5, 21, 223, 144, 36, 213, 75, 70, 250, 56, 5, 117, 57,
          241, 167, 2, 32, 59, 99, 134, 117, 177, 215, 159, 163, 16, 46, 58, 115, 160,
          74, 140, 86, 134, 241, 163, 252, 99, 86, 152, 24, 148, 162, 129, 108, 219,
          42, 7, 57>>
      }
    end

    test "returns true when valid signature present", %{pk: pk, sig: sig} do
      {:ok, env} = Txpost.Envelope.build(payload: @payload, pubkey: pk, signature: sig)
      assert Txpost.Envelope.verify(env)
    end

    test "returns false when invalid signature present", %{pk: pk} do
      {:ok, env} = Txpost.Envelope.build(payload: @payload, pubkey: pk, signature: "notasig")
      refute Txpost.Envelope.verify(env)
    end

    test "returns false when wrong pubkey present", %{pk2: pk, sig: sig} do
      {:ok, env} = Txpost.Envelope.build(payload: @payload, pubkey: pk, signature: sig)
      refute Txpost.Envelope.verify(env)
    end

    test "returns false when no sig or pubkey present" do
      {:ok, env} = Txpost.Envelope.build(payload: @payload)
      refute Txpost.Envelope.verify(env)
    end
  end

end

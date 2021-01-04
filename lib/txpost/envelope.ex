defmodule Txpost.Envelope do
  @moduledoc """
  CBOR Envelope module, implements BRFC `5b82a2ed7b16` ([CBOR Tx Envelope](cbor-tx-envelope.md)).

  BRFC `5b82a2ed7b16` defines a standard for serializing a CBOR payload in order
  to have consistnency when signing the payload with a ECDSA keypair.

  The `:payload` attribute is a CBOR encoded binary [`Payload`](`t:Txpost.Payload.t/0`).

  The `:pubkey` and `:signature` attributes are optional binaries.

  ## Examples

  Example envelope with an unsigned payload.

      %Txpost.Envelope{
        payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      }

  Example envelope with an signed payload.

      %Txpost.Envelope{
        payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        pubkey: <<2, 170, 75, 142, 232, 142, 111, 76, 138, 31, 212, 197, 4, 20, 227, 157, 8, 252, 150, 79, 61, 83, 205, 99, 54, 225, 193, 254, 122, 200, 147, 51, 180>>,
        signature: <<48, 68, 2, 32, 24, 134, 241, 47, 243, 122, 86, 199, 199, 220, 173, 209, 38, 189, 238, 84, 197, 20, 218, 193, 190, 35, 88, 95, 214, 137, 204, 206, 156, 21, 223, 5, 2, 32, 67, 243, 10, 255, 17, 52, 68, 176, 250, 253, 199, 208, 16, 167, 132, 183, 206, 49, 147, 241, 61, 117, 231, 254, 197, 52, 109, 45, 247, 78, 210, 62>>
      }
  """
  alias Txpost.Payload
  import Txpost.Utils.Params

  defstruct [:payload, :pubkey, :signature]

  @typedoc "CBOR Envelope"
  @type t :: %__MODULE__{
    payload: binary,
    pubkey: binary | nil,
    signature: binary | nil
  }


  @doc """
  Validates the given parameters and returns an [`Envelope`](`t:t/0`) struct or
  returns a validation error message.

  Parameters can be passed as either a map or keyword list. The payload
  attribute can be an already encoded CBOR binary or a [`Payload`](`t:Txpost.Payload.t/0`) struct.

  ## Examples

      iex> Txpost.Envelope.build(%{
      ...>   payload: %Txpost.Payload{data: %{"rawtx" => <<1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 >>}}
      ...> })
      {:ok, %Txpost.Envelope{
        payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        pubkey: nil,
        signature: nil
      }}

  Returns an error when given invalid params.

      iex> Txpost.Envelope.build(payload: ["not a valid payload"])
      {:error, "Invalid param: payload"}
  """
  @spec build(map | keyword) :: {:ok, t} | {:error, String.t}
  def build(params) when is_map(params) or is_list(params) do
    params
    |> normalize_params([:payload, :pubkey, :signature])
    |> encode_payload
    |> validate_param(:payload, &is_binary/1)
    |> validate_param(:pubkey, &is_binary/1, allow_blank: true)
    |> validate_param(:signature, &is_binary/1, allow_blank: true)
    |> case do
      {:ok, params} ->
        {:ok, struct(__MODULE__, params)}

      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc """
  Decodes the given CBOR binary and returns an [`Envelope`](`t:t/0`) struct or
  returns a validation error message.

  ## Examples

      iex> Txpost.Envelope.decode(<<161, 103, 112, 97, 121, 108, 111, 97, 100, 120, 24, 161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
      {:ok, %Txpost.Envelope{
        payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
        pubkey: nil,
        signature: nil
      }}

  Returns an error when given invalid binary.

      iex> Txpost.Envelope.decode(<<0,1,2,3>>)
      {:error, "Invalid payload binary"}
  """
  @spec decode(binary) :: {:ok, t} | {:error, any}
  def decode(data) when is_binary(data) do
    case CBOR.decode(data) do
      {:ok, data, _} when is_map(data) ->
        data
        |> untag_bytes
        |> build

      {:ok, _, _} ->
        {:error, "Invalid payload binary"}

      {:error, _reason} ->
        {:error, "Invalid payload binary"}
    end
  end


  @doc """
  Decodes the payload of the given [`Envelope`](`t:t/0`) struct and returns a
  [`Payload`](`t:t/0`) struct or returns a validation error message.

  ## Examples

      iex> Txpost.Envelope.decode_payload(%Txpost.Envelope{
      ...>   payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      ...> })
      {:ok, %Txpost.Payload{
        data: %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
        meta: %{}
      }}
  """
  @spec decode_payload(t) :: {:ok, Payload.t} | {:error, any}
  def decode_payload(%__MODULE__{payload: data}),
    do: Payload.decode(data)


  @doc """
  Encodes the given [`Envelope`](`t:t/0`) struct and returns a CBOR binary.

  ## Examples

      iex> Txpost.Envelope.encode(%Txpost.Envelope{
      ...>   payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      ...> })
      <<161, 103, 112, 97, 121, 108, 111, 97, 100, 88, 24, 161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  """
  @spec encode(t) :: binary
  def encode(%__MODULE__{} = env) do
    env
    |> to_map
    |> tag_bytes
    |> CBOR.encode
  end


  @doc """
  Returns the given [`Envelope`](`t:t/0`) struct as a map with stringified keys.
  The pubkey and signature attributes are removed if they are nil.

  ## Examples

      iex> Txpost.Envelope.to_map(%Txpost.Envelope{
      ...>   payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      ...> })
      %{
        "payload" => <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      }
  """
  @spec to_map(t) :: map
  def to_map(%__MODULE__{} = env) do
    env
    |> Map.from_struct
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end


  @doc """
  Signs the [`Envelope`](`t:t/0`) payload with the given ECDSA private key.

  NOT YET IMPLEMENTED
  """
  @spec sign(t, binary) :: t
  def sign(%__MODULE__{} = env, _private_key) do
    IO.warn("Txpost.Envelope.sign/2 not yet implemented", [{__MODULE__, :sign, 2, []}])
    {:ok, env}
    #|> Map.put(:pubkey, "TODO")
    #|> Map.put(:signature, "TODO")
  end

  @doc """
  Verifies the [`Envelope`](`t:t/0`) signature against its payload and public
  key, returning a boolean.

  If no signature or public key is present, returns `false`.

  ## Examples

      iex> Txpost.Envelope.verify(%Txpost.Envelope{
      ...>   payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 106, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      ...>   pubkey: <<2, 170, 75, 142, 232, 142, 111, 76, 138, 31, 212, 197, 4, 20, 227, 157, 8, 252, 150, 79, 61, 83, 205, 99, 54, 225, 193, 254, 122, 200, 147, 51, 180>>,
      ...>   signature: <<48, 68, 2, 32, 24, 134, 241, 47, 243, 122, 86, 199, 199, 220, 173, 209, 38, 189, 238, 84, 197, 20, 218, 193, 190, 35, 88, 95, 214, 137, 204, 206, 156, 21, 223, 5, 2, 32, 67, 243, 10, 255, 17, 52, 68, 176, 250, 253, 199, 208, 16, 167, 132, 183, 206, 49, 147, 241, 61, 117, 231, 254, 197, 52, 109, 45, 247, 78, 210, 62>>
      ...> })
      true
  """
  @spec verify(t) :: boolean
  def verify(%__MODULE__{pubkey: pubkey, signature: sig})
    when is_nil(pubkey) or is_nil(sig),
    do: false

  def verify(%__MODULE__{payload: payload, pubkey: pubkey, signature: sig}),
    do: :crypto.verify(:ecdsa, :sha256, payload, sig, [pubkey, :secp256k1])


  # Encodes the payload struct as a CBOR binary
  defp encode_payload(%{payload: %Payload{}} = params),
    do: update_in(params.payload, &Payload.encode/1)
  defp encode_payload(params), do: params

  # TODO
  defp tag_bytes(%{} = env),
    do: Enum.map(env, &tag_bytes/1) |> Enum.into(%{})
  defp tag_bytes({key, value})
    when key in ["payload", "pubkey", "signature"]
    and is_binary(value),
    do: {key, %CBOR.Tag{tag: :bytes, value: value}}
  defp tag_bytes(data), do: data

  # TODO
  defp untag_bytes(%{} = env),
    do: Enum.map(env, &untag_bytes/1) |> Enum.into(%{})
  defp untag_bytes({key, %CBOR.Tag{tag: :bytes, value: value}})
    when key in ["payload", "pubkey", "signature"]
    and is_binary(value),
    do: {key, value}
  defp untag_bytes(data), do: data

end

defmodule Txpost.Envelope.InvalidSignatureError do
  @moduledoc "Error raised when Envelope signature is invalid."

  defexception message: "invalid CBOR Envelope signature", plug_status: 403
end

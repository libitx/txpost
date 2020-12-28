defmodule Txpost.Envelope do
  @moduledoc """
  TODO
  """
  alias Txpost.Payload
  import Txpost.Utils.Params

  defstruct [:payload, :pubkey, :signature]

  @typedoc "TODO"
  @type t :: %__MODULE__{
    payload: Payload.t,
    pubkey: binary | nil,
    signature: binary | nil
  }


  @doc """
  TODO
  """
  @spec build(map | keyword) :: {:ok, t} | {:error, String.t}
  def build(params) when is_map(params) or is_list(params) do
    params
    |> normalize_params([:payload, :pubkey, :signature])
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
  TODO
  """
  @spec decode(binary) :: {:ok, t} | {:error, any}
  def decode(data) when is_binary(data) do
    case CBOR.decode(data) do
      {:ok, data, _} when is_map(data) ->
        build(data)

      {:ok, _, _} ->
        {:error, "Invalid payload binary"}

      {:error, _reason} ->
        {:error, "Invalid payload binary"}
    end
  end


  @doc """
  TODO
  """
  @spec decode_payload(t) :: {:ok, Payload.t} | {:error, any}
  def decode_payload(%__MODULE__{payload: data}),
    do: Payload.decode(data)


  @doc """
  TODO
  """
  @spec encode(t) :: binary
  def encode(%__MODULE__{} = env) do
    env
    |> to_map
    |> CBOR.encode
  end


  @doc """
  TODO
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
  TODO
  """
  @spec sign(t, binary) :: t
  def sign(%__MODULE__{} = env, _private_key) do
    env
    |> Map.put(:pubkey, "TODO")
    |> Map.put(:signature, "TODO")
  end

  @doc """
  TODO
  """
  @spec verify(t) :: boolean
  def verify(%__MODULE__{pubkey: pubkey, signature: sig})
    when is_nil(pubkey) or is_nil(sig),
    do: false

  def verify(%__MODULE__{pubkey: _pubkey, signature: _sig}) do
    # ECDSA.verify(sig, hash, pubkey)
    false
  end

end

defmodule Txpost.Envelope.InvalidSignatureError do
  @moduledoc "Error raised when Envelope signature is invalid."

  defexception message: "invalid CBOR Envelope signature", plug_status: 403
end

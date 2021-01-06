defmodule Txpost.Payload do
  @moduledoc """
  Request payload module, implements BRFC `c9a2975b3d19` ([CBOR Tx Payload](cbor-tx-payload.md)).

  BRFC `c9a2975b3d19` defines a simple structure for encoding a raw Bitcoin transaction
  alongside arbitrary data attributes and meta data in a CBOR encoded binary.

  The `:data` attribute is either be a map with a single raw transaction
  alongside any other attributes, or alternatively it can be a list of maps
  containing multiple sets of raw transactions with additional attributes. This
  allows multiple transactions to be encoded in a single payload.

  The `:meta` attribute is a map which can contain any other arbitrary infomation
  which can be used to help handle the request.

  ## Examples

  Example payload containing a single transaction.

      %Txpost.Payload{
        data: %{
          "rawtx" => <<1, 0 ,0 ,0, ...>>,
          "type" => "article"
        },
        meta: %{
          "path" => "/posts"
        }
      }

  Example payload containing a list of transactions.

      %Txpost.Payload{
        data: [%{
          "rawtx" => <<1, 0 ,0 ,0, ...>>,
          "type" => "article"
        }, %{
          "rawtx" => <<1, 0 ,0 ,0, ...>>,
          "type" => "article"
        }],
        meta: %{
          "path" => "/posts"
        }
      }
  """
  alias Txpost.Envelope
  import Txpost.Utils.Params

  defstruct data: nil, meta: %{}

  @typedoc "CBOR Request Payload"
  @type t :: %__MODULE__{
    data: map | list(map),
    meta: map
  }


  @doc """
  Validates the given parameters and returns a [`Payload`](`t:t/0`) struct or
  returns a validation error message.

  Parameters can be passed as either a map or keyword list.

  ## Examples

      iex> Txpost.Payload.build(data: %{"rawtx" => <<1, 0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 >>})
      {:ok, %Txpost.Payload{
        data: %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
        meta: %{}
      }}

  Returns an error when given invalid params.

      iex> Txpost.Payload.build(data: "not a map")
      {:error, "Invalid param: data"}
  """
  @spec build(map | keyword) :: {:ok, t} | {:error, String.t}
  def build(params) when is_map(params) or is_list(params) do
    params
    |> normalize_params([:data, :meta])
    |> validate_param(:data, &valid_data/1)
    |> validate_param(:meta, &is_map/1, allow_blank: true)
    |> case do
      {:ok, params} ->
        {:ok, struct(__MODULE__, params)}

      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc """
  Decodes the given CBOR binary and returns a [`Payload`](`t:t/0`) struct or
  returns a validation error message.

  ## Examples

      iex> Txpost.Payload.decode(<<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
      {:ok, %Txpost.Payload{
        data: %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
        meta: %{}
      }}

  Returns an error when given invalid binary.

      iex> Txpost.Payload.decode(<<0,1,2,3>>)
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

      {:error, reason} ->
        {:error, reason}
    end
  end


  @doc """
  Encodes the given [`Payload`](`t:t/0`) struct and returns a CBOR binary.

  ## Examples

      iex> Txpost.Payload.encode(%Txpost.Payload{
      ...>   data: %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
      ...> })
      <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  """
  @spec encode(t) :: binary
  def encode(%__MODULE__{} = payload) do
    payload
    |> to_map
    |> tag_bytes
    |> CBOR.encode
  end


  @doc """
  Encodes the given [`Payload`](`t:t/0`) struct as a CBOR binary and wraps it
  within an [`Envelope`](`t:Envelopet/0`) struct.

  ## Examples

      iex> Txpost.Payload.encode_envelope(%Txpost.Payload{
      ...>   data: %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
      ...> })
      %Txpost.Envelope{
        payload: <<161, 100, 100, 97, 116, 97, 161, 101, 114, 97, 119, 116, 120, 74, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      }
  """
  @spec encode_envelope(t) :: {:ok, Envelope.t}
  def encode_envelope(%__MODULE__{} = payload),
    do: struct(Envelope, payload: encode(payload))


  @doc """
  Returns the given [`Payload`](`t:t/0`) struct as a map with stringified keys.
  The meta attribute is removed if it is an empty map.

  ## Examples

      iex> Txpost.Payload.to_map(%Txpost.Payload{
      ...>   data: %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
      ...> })
      %{
        "data" => %{"rawtx" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}
      }
  """
  @spec to_map(t) :: map
  def to_map(%__MODULE__{} = payload) do
    payload
    |> Map.from_struct
    |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end)
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end


  # Ensures the given value is a valid data map or list of maps.
  defp valid_data(%{rawtx: rawtx}) when is_binary(rawtx), do: true
  defp valid_data(%{"rawtx" => rawtx}) when is_binary(rawtx), do: true
  defp valid_data(items) when is_list(items),
    do: Enum.all?(items, &valid_data/1)
  defp valid_data(_), do: false

  # Wraps known binary elements in CBOR bytes tag
  defp tag_bytes(%{"data" => data} = payload)
    when is_map(data) or is_list(data),
    do: update_in(payload, ["data"], &tag_bytes/1)
  defp tag_bytes(%{"rawtx" => rawtx} = data) when is_binary(rawtx),
    do: Map.put(data, "rawtx", %CBOR.Tag{tag: :bytes, value: rawtx})
  defp tag_bytes(%{"rawtx" => %CBOR.Tag{tag: :bytes, value: rawtx}} = data),
    do: Map.put(data, "rawtx", rawtx)
  defp tag_bytes([item | rest]),
    do: [tag_bytes(item) | tag_bytes(rest)]
  defp tag_bytes(data), do: data

  # TODO
  defp untag_bytes(%{"data" => data} = payload)
    when is_map(data) or is_list(data),
    do: update_in(payload, ["data"], &untag_bytes/1)
  defp untag_bytes(%{"rawtx" => %CBOR.Tag{tag: :bytes, value: rawtx}} = data),
    do: Map.put(data, "rawtx", rawtx)
  defp untag_bytes([item | rest]),
    do: [untag_bytes(item) | untag_bytes(rest)]
  defp untag_bytes(data), do: data

end

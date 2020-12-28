defmodule Txpost.Payload do
  @moduledoc """
  TODO
  """
  import Txpost.Utils.Params

  defstruct [:data, :meta, :rawtx]

  @typedoc "TODO"
  @type t :: %__MODULE__{
    data: map | nil,
    meta: map | nil,
    rawtx: binary
  }


  @doc """
  TODO
  """
  @spec build(map | keyword) :: {:ok, t} | {:error, String.t}
  def build(params) when is_map(params) or is_list(params) do
    params
    |> normalize_params([:data, :meta, :rawtx])
    |> validate_param(:data, &is_map/1, allow_blank: true)
    |> validate_param(:meta, &is_map/1, allow_blank: true)
    |> validate_param(:rawtx, &is_binary/1)
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
  @spec encode(t) :: binary
  def encode(%__MODULE__{} = payload) do
    payload
    |> to_map(include_nil: false)
    |> CBOR.encode
  end


  @doc """
  TODO
  """
  @spec to_map(t, keyword) :: map
  def to_map(%__MODULE__{} = payload, opts \\ []) do
    include_nil = Keyword.get(opts, :include_nil, true)
    payload
    |> Map.from_struct
    |> put_map_or_drop_key(:data, include_nil)
    |> put_map_or_drop_key(:meta, include_nil)
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end


  # Defaults the key to a map or drops the key
  defp put_map_or_drop_key(map, key, false) do
    case Map.get(map, key) do
      nil -> Map.delete(map, key)
      _ -> map
    end
  end

  defp put_map_or_drop_key(map, key, _) do
    case Map.get(map, key) do
      nil -> Map.put(map, key, %{})
      _ -> map
    end
  end

end

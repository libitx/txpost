defmodule Txpost.Payload do
  @moduledoc """
  TODO
  """
  import Txpost.Utils.Params

  defstruct data: nil, meta: %{}

  @typedoc "TODO"
  @type t :: %__MODULE__{
    data: map | list(map),
    meta: map
  }


  @doc """
  TODO
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
    |> to_map
    |> CBOR.encode
  end


  @doc """
  TODO
  """
  @spec to_map(t) :: map
  def to_map(%__MODULE__{} = payload) do
    payload
    |> Map.from_struct
    |> Enum.reject(fn {_k, v} -> Enum.empty?(v) end)
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end


  # TODO
  defp valid_data(%{rawtx: rawtx}) when is_binary(rawtx), do: true
  defp valid_data(%{"rawtx" => rawtx}) when is_binary(rawtx), do: true
  defp valid_data(items) when is_list(items),
    do: Enum.all?(items, &valid_data/1)
  defp valid_data(_), do: false

end

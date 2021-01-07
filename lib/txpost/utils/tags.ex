defmodule Txpost.Utils.Tags do
  @moduledoc false

  @doc """
  Recursively wraps not-utf8 binaries in a CBOR bytes tag
  """
  @spec entag(any) :: any
  def entag(%CBOR.Tag{} = value), do: value
  def entag(value) when is_binary(value) do
    if String.valid?(value),
      do: value,
      else: %CBOR.Tag{tag: :bytes, value: value}
  end
  def entag(value) when is_map(value),
    do: Enum.map(value, &entag/1) |> Enum.into(%{})
  def entag([head | tail]), do: [entag(head) | entag(tail)]
  def entag({key, value}), do: {entag(key), entag(value)}
  def entag(value), do: value


  @doc """
  Recursively unwraps CBOR bytes tags as binaries
  """
  @spec detag(any) :: any
  def detag(%CBOR.Tag{tag: :bytes, value: value}), do: value
  def detag(value) when is_map(value),
    do: Enum.map(value, &detag/1) |> Enum.into(%{})
  def detag([head | tail]), do: [detag(head) | detag(tail)]
  def detag({key, value}), do: {detag(key), detag(value)}
  def detag(value), do: value

end

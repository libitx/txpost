defmodule Txpost.Utils.Params do
  @moduledoc false

  @doc """
  Normalizes the given maps keys by converting all keys to strings, taking the
  allowed keys, and converting back to atoms
  """
  @spec normalize_params(map, list) :: map
  def normalize_params(params, allowed) do
    params
    |> Map.new(fn {k, v} -> {normalize_key(k), v} end)
    |> Map.take(Enum.map(allowed, &Atom.to_string/1))
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end


  @doc """
  Normalizes the given key as a string
  """
  @spec normalize_key(atom | String.t) :: String.t
  def normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  def normalize_key(key), do: key


  @doc """
  Validates the parameter at the specified key, using the given validator
  function.
  """
  @spec validate_param(map, atom, function, keyword) :: {:ok, map} | {:error, String.t}
  def validate_param(params, key, validator, opts \\ [])

  def validate_param(params, key, validator, opts) when is_map(params),
    do: validate_param({:ok, params}, key, validator, opts)

  def validate_param({:error, reason}, _key, _validator, _opts),
    do: {:error, reason}

  def validate_param({:ok, params}, key, validator, opts) do
    val = Map.get(params, key)
    Keyword.get(opts, :allow_blank, false)
    |> case do
      true -> is_nil(val) || apply(validator, [val])
      _ -> apply(validator, [val])
    end
    |> case do
      true -> {:ok, params}
      false -> {:error, "Invalid param: #{key}"}
    end
  end

end

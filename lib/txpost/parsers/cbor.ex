defmodule Txpost.Parsers.CBOR do
  @moduledoc """
  A `Plug.Parsers` module for parsing CBOR request bodies.

  CBOR documents that dont decode to maps are parsed into a `"_cbor"` key to
  allow param merging. An empty request body is parsed as an empty map.

  ## Example

  Add the parser your app's list of parsers.

      plug Plug.Parsers,
        parsers: [
          :json,
          Txpost.Parsers.CBOR
        ]

  """
  @behaviour Plug.Parsers


  @impl true
  def init(opts) do
    {body_reader, opts} = Keyword.pop(opts, :body_reader, {Plug.Conn, :read_body, []})
    {decoder, opts} = Keyword.pop(opts, :cbor_decoder, {CBOR, :decode, []})
    {body_reader, decoder, opts}
  end

  @impl true
  def parse(conn, "application", subtype, _params, {{mod, fun, args}, decoder, opts}) do
    if subtype == "cbor" or String.ends_with?(subtype, "+cbor") do
      apply(mod, fun, [conn, opts | args]) |> decode(decoder)
    else
      {:next, conn}
    end
  end

  def parse(conn, _type, _subtype, _params, _opts) do
    {:next, conn}
  end

  defp decode({:ok, "", conn}, _decoder) do
    {:ok, %{}, conn}
  end


  defp decode({:ok, body, conn}, {module, fun, args}) do
    case apply(module, fun, [body | args]) do
      {:ok, terms, _rest} when is_map(terms) ->
        {:ok, normalize(terms), conn}

      {:ok, terms, _rest} ->
        {:ok, %{"_cbor" => normalize(terms)}, conn}

      {:error, reason} ->
        raise Plug.Parsers.ParseError, exception: reason
    end
  end

  defp decode({:more, _, conn}, _decoder) do
    {:error, :too_large, conn}
  end

  defp decode({:error, :timeout}, _decoder) do
    raise Plug.TimeoutError
  end

  defp decode({:error, _}, _decoder) do
    raise Plug.BadRequestError
  end

  defp normalize(%CBOR.Tag{tag: :bytes, value: value}), do: value
  defp normalize([term | terms]), do: [normalize(term) | normalize(terms)]
  defp normalize(%{} = terms),
    do: Enum.map(terms, &normalize/1) |> Enum.into(%{})
  defp normalize({key, val}), do: {key, normalize(val)}
  defp normalize(value), do: value

end

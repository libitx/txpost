defmodule Txpost.Parsers.CBOR do
  @moduledoc """
  TODO
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

  # TODO
  defp decode({:ok, "", conn}, _decoder) do
    {:ok, %{}, conn}
  end

  defp decode({:ok, body, conn}, {module, fun, args}) do
    case apply(module, fun, [body | args]) do
      {:ok, terms, _rest} when is_map(terms) ->
        {:ok, terms, conn}

      {:ok, terms, _rest} ->
        {:ok, %{"_cbor" => terms}, conn}

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

end

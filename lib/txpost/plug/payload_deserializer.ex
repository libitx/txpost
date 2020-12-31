defmodule Txpost.Plug.PayloadDeserializer do
  @moduledoc """
  Plug for flattening incoming params decoded from a CBOR request as per BRFC #TODO.

  This will only deserialize a payload when the request has a CBOR-parsable
  content type.

  ## Example

      plug Txpost.Plug.PayloadDeserializer
  """
  import Plug.Conn

  @behaviour Plug


  @impl true
  def init(opts), do: opts


  @impl true
  def call(conn, _opts) do
    content_type = get_req_header(conn, "content-type")

    if Enum.any?(content_type, &valid_content_type/1),
      do: Map.put(conn, :params, flatten_params(conn.params)),
      else: conn
  end


  defp valid_content_type("application/cbor"), do: true
  defp valid_content_type("application/" <> subtype),
    do: String.ends_with?(subtype, "cbor")
  defp valid_content_type(_content_type), do: false


  defp flatten_params(%{"data" => data} = params) when is_map(data) do
    params
    |> Map.merge(data)
    |> Map.delete("data")
  end

  defp flatten_params(%{"data" => data}) when is_list(data) do
    data
  end

  defp flatten_params(params), do: params

end

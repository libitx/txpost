defmodule Txpost.Plug.PayloadDeserializer do
  @moduledoc """
  TODO
  """
  @behaviour Plug


  @impl true
  def init(opts), do: opts


  @impl true
  def call(conn, _opts) do
    conn
    |> Map.put(:params, flatten_params(conn.params))
  end


  # TODO
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

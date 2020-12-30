defmodule Txpost.Router do
  @moduledoc """
  TODO
  """

  @doc """
  TODO
  """
  defmacro __using__(_opts) do
    quote do
      import Plug.Conn
      import Txpost.Router
      @behaviour Plug

      @impl true
      def init(opts), do: opts

      @impl true
      def call(conn, _opts), do: handle_tx(conn, conn.params)
    end
  end

  @callback handle_tx(conn :: Plug.Conn.t, params :: map | list) :: Plug.Conn.t

  @doc """
  TODO
  """
  @spec get_req_meta(Plug.Conn.t) :: map | nil
  def get_req_meta(%{private: %{txpost_payload: payload}}), do: payload.meta
  def get_req_meta(%{params: %{"meta" => meta}}), do: meta
  def get_req_meta(_conn), do: nil

end

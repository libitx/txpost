defmodule Txpost.Plug.EnvelopeRequired do
  @moduledoc """
  Plug for ensuring CBOR requests are sent in a valid CBOR envolope. Implements
  BRFC #TODO.

  ## Options

  * `:ensure_signed` - Ensures the [`Envelope`](`t:Txpost.Envelope.t/0`) is signed with a valid signature or riases an [`InvalidSignatureError`](`Txpost.Envelope.InvalidSignatureError`). Defaults `false`.

  ## Example

      plug Txpost.Plug.EnvelopeRequired, ensure_signed: true

  """
  import Plug.Conn
  alias Txpost.{Envelope, Payload}

  @behaviour Plug


  @impl true
  def init(opts), do: opts


  @impl true
  def call(conn, opts) do
    ensure_signed = Keyword.get(opts, :ensure_signed, false)

    with {:ok, env} <- Envelope.build(conn.params),
         {:ok, env} <- verify_signature(env, ensure_signed),
         {:ok, payload} <- Envelope.decode_payload(env)
    do
      conn
      |> put_private(:txpost_env, env)
      |> put_private(:txpost_payload, payload)
      |> Map.update!(:params, fn params ->
        params
        |> Map.drop(Map.keys(Envelope.to_map(env)))
        |> Map.merge(Payload.to_map(payload))
      end)

    else
      {:error, :not_verified} ->
        raise Txpost.Envelope.InvalidSignatureError

      {:error, _reason} ->
        raise Plug.BadRequestError
    end
  end


  defp verify_signature(env, false), do: {:ok, env}
  defp verify_signature(env, true) do
    case Envelope.verify(env) do
      true -> {:ok, env}
      false -> {:error, :not_verified}
    end
  end

end

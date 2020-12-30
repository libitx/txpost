defmodule Txpost.Plug do
  @moduledoc """
  TODO
  """
  use Plug.Builder
  alias Txpost.Plug.{EnvelopeRequired, PayloadDeserializer}

  plug :envelope_required, builder_opts()
  plug PayloadDeserializer

  defp envelope_required(conn, opts),
    do: EnvelopeRequired.call conn, EnvelopeRequired.init(opts)

end

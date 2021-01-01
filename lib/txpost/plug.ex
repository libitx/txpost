defmodule Txpost.Plug do
  @moduledoc """
  A helper plug that adds the following modules to your pipeline.

  * [`EnvelopeRequired`](`Txpost.Plug.EnvelopeRequired`) - Implements BRFC `5b82a2ed7b16`
  * [`PayloadDeserializer`](`Txpost.Plug.PayloadDeserializer`) - Implements BRFC `c9a2975b3d19`

  Any of the options accepts by the modules above can be passed to this plug.

  ## Example

      plug Txpost.Plug
  """
  use Plug.Builder
  alias Txpost.Plug.{EnvelopeRequired, PayloadDeserializer}

  plug :envelope_required, builder_opts()
  plug PayloadDeserializer

  defp envelope_required(conn, opts),
    do: EnvelopeRequired.call conn, EnvelopeRequired.init(opts)

end

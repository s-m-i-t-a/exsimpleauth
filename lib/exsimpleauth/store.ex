defmodule ExSimpleAuth.Store do
  @moduledoc """
  The auth token store behaviour.
  """

  alias Plug.Conn

  @callback get(conn :: Conn.t(), key :: String.t()) :: Result.t(String.t(), String.t())
end

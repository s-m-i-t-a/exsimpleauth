defmodule ExSimpleAuth.Store.Session do
  @moduledoc """
  Find a token in session.
  """

  @behaviour ExSimpleAuth.Store

  alias Plug.Conn

  @impl true
  def get(%Conn{} = conn, key) when is_binary(key) do
    conn
    |> Conn.get_session(key)
    |> token_to_result()
  end

  defp token_to_result(nil) do
    {:error, "Auth token not found."}
  end

  defp token_to_result(token) do
    {:ok, token}
  end
end

defmodule ExSimpleAuth.Store.Header do
  @moduledoc """
  Find token in http headers.
  """

  @behaviour ExSimpleAuth.Store

  alias Plug.Conn

  @impl true
  def get(%Conn{} = conn, key) when is_binary(key) do
    conn
    |> Conn.get_req_header(key)
    |> token_to_result()
  end

  defp token_to_result([]) do
    {:error, "Auth token not found."}
  end

  defp token_to_result([token | _]) do
    {:ok, token}
  end
end

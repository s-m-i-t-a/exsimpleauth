defmodule ExSimpleAuth.Plug do
  @moduledoc """
  A simple authentication plug.
  """

  alias ExSimpleAuth.Token
  alias Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts) do
    token_header = Keyword.get(opts, :http_header, "x-auth-token")
    get_user = Keyword.get(opts, :get_user) || raise "'get_user' must be set"

    {get_user, token_header}
  end

  @impl true
  def call(conn, {get_user, token_header}) do
    conn
    |> Conn.get_req_header(token_header)
    |> token_to_result()
    |> Result.and_then(&Token.verify/1)
    |> Result.and_then(get_user)
    |> store_user_or_deny_access(conn)
  end

  defp token_to_result([]) do
    {:error, "Auth token not found."}
  end

  defp token_to_result([token | _]) do
    {:ok, token}
  end

  defp store_user_or_deny_access({:ok, user}, conn) do
    Conn.assign(conn, :user, user)
  end

  defp store_user_or_deny_access({:error, err}, conn) do
    conn
    |> Conn.send_resp(
      :unauthorized,
      Poison.encode!(%{status: 401, message: claims_error_to_message(err)})
    )
    |> Conn.halt()
  end

  defp claims_error_to_message(errors) when is_binary(errors) do
    errors
  end

  defp claims_error_to_message(errors) do
    errors
    |> Enum.map(&claim_error/1)
    |> Enum.join("\n")
  end

  defp claim_error(:iss), do: "Invalid issuer."
  defp claim_error(:sub), do: "Invalid subject."
  defp claim_error(:aud), do: "Invalid audience"
  defp claim_error(:exp), do: "Token expired."

  defp claim_error(:nbf),
    do:
      "Welcome time travelers, but I must refuse access to the system to protect the time continuum. Invalid 'Not Before' claim."

  defp claim_error(:iat), do: "Invalid 'Issued At' claim."
  defp claim_error(:jti), do: "Invalid JWT ID."
  defp claim_error(_), do: "Unknown JWT claim error."
end

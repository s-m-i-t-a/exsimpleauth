defmodule ExSimpleAuth.Plug do
  @moduledoc """
  A simple authentication plug.

  ## Options

  * `:http_header` - The name of the HTTP *request* header to check for
    existing request token. Default value is "x-auth-token".
  * `:get_user` - The function returns the user.
    It has input data decoded from the JWT token and returns either `{:ok, user}` or `{:error, message}`.
  * `:key` - decryption key. If not used,
    then read `SECRET_KEY` variable from system environment.

  ## Examples

      plug ExSimpleAuth.Plug, http_header: "custom-auth-token", get_user: &MyUser.get/1


      iex> key = "y):'QGE8M-b+MEKl@k4e<;*9.BqL=@~B"
      ...> user = %{id: "1234567890"}
      ...> token = ExSimpleAuth.Token.generate(user, key: key)
      ...> defaults = ExSimpleAuth.Plug.init(key: key, get_user: fn %{id: value} -> {:ok, value} end)
      ...> conn = conn(:get, "/foo") |> put_req_header("x-auth-token", token) |> ExSimpleAuth.Plug.call(defaults)
      ...> conn.assigns[:user]
      "1234567890"
  """

  alias ExSimpleAuth.Token
  alias Plug.Conn
  alias Plug.Conn.Status

  @behaviour Plug

  @impl true
  def init(opts) do
    token_header = Keyword.get(opts, :http_header, "x-auth-token")
    get_user = Keyword.get(opts, :get_user) || raise "'get_user' must be set"
    key = Keyword.get(opts, :key, System.get_env("SECRET_KEY"))

    {get_user, token_header, key}
  end

  @impl true
  def call(conn, {get_user, token_header, key}) do
    conn
    |> Conn.get_req_header(token_header)
    |> token_to_result()
    |> Result.and_then(fn data -> Token.verify(data, key: key) end)
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
    |> send_error_resp(
      Conn.get_req_header(conn, "content-type"),
      :unauthorized,
      claims_error_to_message(err)
    )
    |> Conn.halt()
  end

  defp send_error_resp(conn, ["application/json" | _], status, msg) do
    status = Status.code(status)

    conn
    |> Conn.put_resp_header("content-type", "application/json")
    |> Conn.send_resp(
      status,
      Poison.encode!(%{status: status, message: msg})
    )
  end

  defp send_error_resp(conn, _content_type, status, msg) do
    status = Status.code(status)

    conn
    |> Conn.put_resp_header("content-type", "text/plain")
    |> Conn.send_resp(status, msg)
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

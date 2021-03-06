defmodule ExSimpleAuth.Plug do
  @moduledoc """
  A simple authentication plug.

  ## Options

  * `:auth_token_key` - The key where the auth token is stored.  Default value is "x-auth-token".
  * `:store` - auth token store. Supported stores is `:header`, `:session`. Default is `:header`.
  * `:reject` - When is `true`, then request ends with _unauthorized_ status and it's sent to the client.
    Default is `true`.
  * `:get_user` - The function returns the user.
    It has input data decoded from the JWT token and returns either `{:ok, user}` or `{:error, message}`.
  * `:key` - decryption key. If not used,
    then read `SECRET_KEY` variable from system environment.

  ## Examples

      plug ExSimpleAuth.Plug, auth_token_key: "custom-auth-token", get_user: &MyUser.get/1


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

  defmodule Opts do
    @moduledoc false
    defstruct auth_token_key: "x-auth-token",
              store: ExSimpleAuth.Store.Header,
              reject?: true,
              get_user: nil,
              key: nil
  end

  @behaviour Plug

  @impl true
  def init(opts) when is_list(opts) do
    %Opts{
      auth_token_key: Keyword.get(opts, :auth_token_key, "x-auth-token"),
      store: opts |> Keyword.get(:store, :header) |> get_store(),
      reject?: Keyword.get(opts, :reject?, true),
      get_user: Keyword.get(opts, :get_user) || raise("'get_user' must be set"),
      key: Keyword.get(opts, :key)
    }
  end

  @impl true
  def call(%Conn{} = conn, %Opts{key: nil} = opts) do
    call(conn, Map.put(opts, :key, System.get_env("SECRET_KEY")))
  end

  @impl true
  def call(%Conn{} = conn, %Opts{
        get_user: get_user,
        auth_token_key: auth_token_key,
        reject?: reject?,
        store: store,
        key: key
      })
      when is_function(get_user, 1) and is_binary(auth_token_key) and is_atom(store) and
             is_binary(key) and is_boolean(reject?) do
    conn
    |> store.get(auth_token_key)
    |> Result.and_then(fn data -> Token.verify(data, key: key) end)
    |> Result.and_then(get_user)
    |> Result.map(fn user -> Conn.assign(conn, :user, user) end)
    |> Result.map_error(fn err -> Conn.assign(conn, :auth_error, err) end)
    |> deny_access(reject?)
  end

  defp get_store(:header) do
    ExSimpleAuth.Store.Header
  end

  defp get_store(:session) do
    ExSimpleAuth.Store.Session
  end

  defp deny_access({:ok, %Conn{} = conn}, _reject) do
    conn
  end

  defp deny_access({:error, %Conn{assigns: %{auth_error: err}} = conn}, true) do
    conn
    |> send_error_resp(
      Conn.get_req_header(conn, "content-type"),
      :unauthorized,
      claims_error_to_message(err)
    )
    |> Conn.halt()
  end

  defp deny_access({:error, %Conn{assigns: %{auth_error: err}} = conn}, false) do
    Conn.assign(conn, :auth_error, claims_error_to_message(err))
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

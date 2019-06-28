defmodule ExSimpleAuth.Token do
  @moduledoc """
  Genrate and verify token
  """

  @empty [nil, ""]

  @doc """
  Check the supplied token and it's expiration.

  ## Options

  * `:key` - decryption key. If not used,
    then read `SECRET_KEY` variable from system environment.

  ## Returns

  * `{:ok, data}` - token is valid.
  * `{:error, "invalid JWT"}` - invalid token
  * `{:error, [:exp,...]}` - invalid claim (eg. token expired)

  ## Examples

  returns data if token is valid

      iex> key = "y):'QGE8M-b+MEKl@k4e<;*9.BqL=@~B"
      ...> data = %{foo: 1234}
      ...> token = ExSimpleAuth.Token.generate(data, key: key)
      ...> ExSimpleAuth.Token.verify(token, key: key)
      {:ok, %{foo: 1234}}

  returns expiration error when token expire

      iex> key = "y):'QGE8M-b+MEKl@k4e<;*9.BqL=@~B"
      ...> data = %{foo: 1234}
      ...> token = ExSimpleAuth.Token.generate(data, key: key, expiration: 0)
      ...> ExSimpleAuth.Token.verify(token, key: key)
      {:error, [:exp]}

  returns error if token is invalid

      iex> key = "y):'QGE8M-b+MEKl@k4e<;*9.BqL=@~B"
      ...> data = %{foo: 1234}
      ...> token = ExSimpleAuth.Token.generate(data, key: key)
      ...> key2 = "12345678901234567890123456789012"
      ...> ExSimpleAuth.Token.verify(token, key: key2)
      {:error, "invalid JWT"}
  """
  def verify(token, opts \\ []) do
    key = Keyword.get(opts, :key, System.get_env("SECRET_KEY"))

    options =
      %{}
      |> put_key(key)

    token
    |> JwtClaims.verify(options)
    |> result()
  end

  @doc """
  Generate JWT token with supplied data

  ## Options

  * `:key` - decryption key. If not used,
    then read `SECRET_KEY` variable from system environment.
  * `:expiration` - epiration time in seconds. Should be nonnegative integer.
    Default is 86400 seconds and it is 24 hours.
  * `:iat` - issued at. Unix timestamp.
    Default `DateTime.utc_now() |> DateTime.to_unix()`.

  Returns JWT token as binary (`t:String.t`).

  ## Examples

      iex> key = "y):'QGE8M-b+MEKl@k4e<;*9.BqL=@~B"
      ...> data = %{foo: 1234}
      ...> ExSimpleAuth.Token.generate(data, key: key, iat: 1516788472)
      "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1MTY3ODg0NzIsImV4cCI6MTUxNjg3NDg3MiwiZGF0YSI6eyJmb28iOjEyMzR9fQ.vTHve65J0r48eTQdABKVzVMWj1E1IQCKTKM-OInh2Hk"
  """
  def generate(data, opts \\ []) do
    key = Keyword.get(opts, :key, System.get_env("SECRET_KEY"))
    expiration = Keyword.get(opts, :expiration, 24 * 60 * 60)
    iat = Keyword.get(opts, :iat, DateTime.utc_now() |> DateTime.to_unix())

    options =
      %{}
      |> put_key(key)

    claim()
    |> put_data(data)
    |> put_iat(iat)
    |> put_expiration(expires_in(iat, expiration))
    |> JsonWebToken.sign(options)
  end

  defp put_key(_options, key) when key in @empty do
    raise "Key can't be empty!"
  end

  defp put_key(%{} = options, key) do
    Map.put(options, :key, key)
  end

  defp claim() do
    %{}
  end

  defp put_data(claim, data) do
    Map.put(claim, :data, data)
  end

  defp put_iat(claim, iat) do
    Map.put(claim, :iat, iat)
  end

  defp put_expiration(claim, exp) do
    Map.put(claim, :exp, exp)
  end

  defp expires_in(iat, exp) when is_integer(exp) and exp >= 0 do
    iat + exp
  end

  defp result({:ok, %{data: data}}) do
    {:ok, data}
  end

  defp result(error) do
    error
  end
end

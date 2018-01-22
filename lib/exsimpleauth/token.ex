defmodule ExSimpleAuth.Token do
  @moduledoc """
  Genrate and verify token
  """

  @empty [nil, ""]

  def verify(token, args \\ []) do
    key = Keyword.get(args, :key, System.get_env("SECRET_KEY"))

    opts =
      %{}
      |> put_key(key)

    token
    |> JwtClaims.verify(opts)
  end

  def generate(data, args \\ []) do
    key = Keyword.get(args, :key, System.get_env("SECRET_KEY"))
    expiration = Keyword.get(args, :expiration, 24 * 60 * 60)

    opts =
      %{}
      |> put_key(key)

    claim()
    |> put_data(data)
    |> put_expiration(expires_in(expiration))
    |> JsonWebToken.sign(opts)
  end

  defp put_key(_opts, key) when key in @empty do
    raise "Key can't be empty!"
  end

  defp put_key(%{} = opts, key) do
    Map.put(opts, :key, key)
  end

  defp claim() do
    %{}
  end

  defp put_data(claim, data) do
    Map.put(claim, :data, data)
  end

  defp put_expiration(claim, exp) do
    Map.put(claim, :exp, exp)
  end

  defp expires_in(exp) when is_integer(exp) and exp >= 0 do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> Kernel.+(exp)
  end
end

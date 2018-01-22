defmodule ExSimpleAuth do
  @moduledoc """
  A simple authentication library
  """

  alias ExSimpleAuth.Token

  defdelegate verify(data), to: Token
  defdelegate generate(data, expiration), to: Token
end

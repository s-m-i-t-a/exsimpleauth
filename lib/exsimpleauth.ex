defmodule ExSimpleAuth do
  @moduledoc """
  A simple authentication library
  """

  alias ExSimpleAuth.Token

  defdelegate verify(data, opts \\ []), to: Token
  defdelegate generate(data, opts \\ []), to: Token
end

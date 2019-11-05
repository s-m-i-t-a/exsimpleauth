defmodule ExSimpleAuth.Store.SessionTest do
  use ExUnit.Case
  use Plug.Test
  doctest ExSimpleAuth.Store.Session

  alias ExSimpleAuth.Store.Session

  test "should find auth token in session" do
    rv =
      :get
      |> conn("/")
      |> init_test_session(%{"x-auth-token" => "foo"})
      |> Session.get("x-auth-token")

    assert rv == {:ok, "foo"}
  end

  test "should return error if token not found" do
    {:error, msg} =
      :get
      |> conn("/")
      |> init_test_session(%{})
      |> Session.get("x-auth-token")

    assert msg =~ ~r/not found/
  end
end

defmodule PlugTest do
  use ExUnit.Case
  use Plug.Test
  doctest ExSimpleAuth.Plug

  alias ExSimpleAuth.Plug, as: AuthPlug
  alias ExSimpleAuth.Token

  alias Plug.Conn

  test "should init raise error if get_user function ins't supplied" do
    assert_raise RuntimeError, "'get_user' must be set", fn ->
      AuthPlug.init([])
    end
  end

  test "should store user to connection" do
    user = %{id: "1234567890"}
    defaults = AuthPlug.init(get_user: fn value -> {:ok, value} end)

    rv =
      :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-auth-token", Token.generate(user))
      |> AuthPlug.call(defaults)

    assert rv.assigns[:user] == user
  end

  test "should reject access if token is bad" do
    user = %{id: "1234567891"}
    defaults = AuthPlug.init(get_user: fn value -> {:ok, value} end)

    %Conn{halted: true, status: 401, resp_body: body} =
      :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-auth-token", Token.generate(user, expiration: 0))
      |> AuthPlug.call(defaults)

    data = Poison.decode!(body)

    assert data["status"] == 401
    assert data["message"] == "Token expired."
  end

  test "should reject access if token not found" do
    defaults = AuthPlug.init(get_user: fn value -> {:ok, value} end)

    %Conn{halted: true, status: 401, resp_body: body} =
      :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> AuthPlug.call(defaults)

    data = Poison.decode!(body)

    assert data["status"] == 401
    assert data["message"] == "Auth token not found."
  end

  test "should return text/plain if content type isn't set" do
    defaults = AuthPlug.init(get_user: fn value -> {:ok, value} end)

    %Conn{halted: true, status: 401, resp_body: body, resp_headers: headers} =
      :get
      |> conn("/foo")
      |> AuthPlug.call(defaults)

    assert headers |> Enum.any?(fn header -> header == {"content-type", "text/plain"} end)
    assert body == "Auth token not found."
  end
end

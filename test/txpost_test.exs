defmodule TxpostTest do
  use ExUnit.Case
  doctest Txpost

  test "greets the world" do
    assert Txpost.hello() == :world
  end
end

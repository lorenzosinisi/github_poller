defmodule GithubPollerTest do
  use ExUnit.Case
  doctest GithubPoller

  test "greets the world" do
    assert GithubPoller.hello() == :world
  end
end

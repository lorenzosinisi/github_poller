defmodule Github.RepoTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Github.Repo
  doctest Github.Repo

  @opts [
    api_token: "TOKEN",
    owner: "lorenzosinisi",
    repo: "github_poller_test",
    notify: nil,
    every: 5000
  ]

  # notify the same process by default
  defp options(opts \\ [notify: self()]) do
    Keyword.merge(@opts, opts)
  end

  describe "new/0" do
    test "assigns the notificable process as self()" do
      assert %Github.Repo{
               every: 5000,
               notify: self()
             } == Repo.new()
    end

    test "assigns has to be checked every 5 seconds" do
      assert %Github.Repo{
               every: 5000,
               notify: self()
             } == Repo.new()
    end
  end

  describe "update_state/2" do
    test "on the first run does not return changes" do
      state = options(repo_state: %{}) |> Enum.into(Repo.new())
      new_state = options(repo_state: %{"1" => %{hash: "123"}}) |> Enum.into(Repo.new())

      assert {
               %{},
               %Github.Repo{
                 api_token: "TOKEN",
                 changes: %{},
                 every: 5000,
                 notify: nil,
                 owner: "lorenzosinisi",
                 repo: "github_poller_test",
                 repo_state: %{"1" => %{hash: "123"}}
               }
             } == Repo.update_state(state, new_state)
    end

    test "on the second run does return changes" do
      state = options(repo_state: %{"1" => %{hash: "123"}}) |> Enum.into(Repo.new())
      new_state = options(repo_state: %{"1" => %{hash: "124"}}) |> Enum.into(Repo.new())

      assert {
               %{"1" => %{hash: "124"}},
               %Github.Repo{
                 api_token: "TOKEN",
                 changes: %{},
                 every: 5000,
                 notify: nil,
                 owner: "lorenzosinisi",
                 repo: "github_poller_test",
                 repo_state: %{"1" => %{hash: "124"}}
               }
             } ==
               Repo.update_state(state, new_state)
    end

    test "when a title changes it is ignored" do
      state = options(repo_state: %{"1" => %{hash: "124", title: "a"}}) |> Enum.into(Repo.new())

      new_state =
        options(repo_state: %{"1" => %{hash: "124", title: "b"}}) |> Enum.into(Repo.new())

      assert {
               %{},
               %Github.Repo{
                 api_token: "TOKEN",
                 changes: %{},
                 every: 5000,
                 notify: nil,
                 owner: "lorenzosinisi",
                 repo: "github_poller_test",
                 repo_state: %{"1" => %{hash: "124", title: "b"}}
               }
             } ==
               Repo.update_state(state, new_state)
    end

    test "when a number changes and so a new PR is added" do
      state = options(repo_state: %{"1" => %{hash: "124", title: "a"}}) |> Enum.into(Repo.new())

      new_state =
        options(repo_state: %{"3" => %{hash: "124", title: "b"}}) |> Enum.into(Repo.new())

      assert {
               %{"3" => %{hash: "124", title: "b"}},
               %Github.Repo{
                 api_token: "TOKEN",
                 changes: %{},
                 every: 5000,
                 notify: nil,
                 owner: "lorenzosinisi",
                 repo: "github_poller_test",
                 repo_state: %{
                   "1" => %{hash: "124", title: "a"},
                   "3" => %{hash: "124", title: "b"}
                 }
               }
             } ==
               Repo.update_state(state, new_state)
    end
  end

  describe "protocol Collectable" do
    test "into/1 with default args" do
      opts = options()

      assert %Github.Repo{
               api_token: "TOKEN",
               changes: %{},
               every: 5000,
               notify: self(),
               owner: "lorenzosinisi",
               repo: "github_poller_test",
               repo_state: %{}
             } == Enum.into(opts, Repo.new())
    end

    test "into/1 with wrong args" do
      opts = options(notify: self(), something: true)
      assert_raise KeyError, fn -> Enum.into(opts, Repo.new()) end
    end
  end
end

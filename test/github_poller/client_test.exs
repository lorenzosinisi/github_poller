defmodule Github.ClientTest do
  @moduledoc false
  use ExUnit.Case
  alias Github.Client
  doctest Github.Poller

  describe "lastest_prs/2 errored" do
    setup do
      old_client = Application.get_env(:github_poller, :http_client)
      Application.put_env(:github_poller, :http_client, Github.HttpFakeClientError)

      on_exit(fn ->
        Application.put_env(:github_poller, :http_client, old_client)
      end)
    end

    test "when the response is something else" do
      assert Client.latest_prs("Token", "lorenzosinisi", "somerepo") ==
               {:error, "400:\nsomething went wrong"}
    end
  end

  describe "lastest_prs/2 successful" do
    test "when the response is 200 and there is a body" do
      assert {:ok,
              [
                %{
                  "baseRefName" => "master",
                  "headRefName" => "relationships-within-objects",
                  "headRefOid" => "369e0d05c258f53215d7b93d0a094884d2d44350",
                  "mergeable" => "UNKNOWN",
                  "number" => 5,
                  "potentialMergeCommit" => nil,
                  "reviews" => %{"nodes" => []},
                  "title" => "Relationships within objects"
                },
                %{
                  "baseRefName" => "master",
                  "headRefName" => "add-timestamp-and-specs",
                  "headRefOid" => "f526c787f9c0b506066b9613e1d50fbd4c1644a0",
                  "mergeable" => "UNKNOWN",
                  "number" => 4,
                  "potentialMergeCommit" => nil,
                  "reviews" => %{"nodes" => []},
                  "title" => "Add timestamp and specs"
                }
              ]} ==
               "Token"
               |> Client.latest_prs("lorenzosinisi", "somerepo")
    end
  end
end

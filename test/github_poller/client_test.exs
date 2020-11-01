defmodule GithubPoller.ClientTest do
  use ExUnit.Case
  alias GithubPoller.Client
  doctest GithubPoller

  defmodule SuccessHttpClient do
    @moduledoc false
    @success_json %{
      "data" => %{
        "repository" => %{
          "pullRequests" => %{
            "nodes" => [
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
            ]
          }
        }
      }
    }

    def request(%{} = _request, module) when is_atom(module) do
      {:ok, %{status: 200, body: Jason.encode!(@success_json)}}
    end
  end

  defmodule ErroredHttpClient do
    @moduledoc false
    def request(%{} = _request, module) when is_atom(module) do
      {:error, %{status: 400, body: "something went wrong"}}
    end
  end

  describe "request/2" do
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
               |> GithubPoller.Client.request(SuccessHttpClient)
    end

    test "when the response is something else" do
      assert {:error, %{status: 400, body: "something went wrong"}} =
               "Token"
               |> Client.latest_prs("lorenzosinisi", "somerepo")
               |> GithubPoller.Client.request(ErroredHttpClient)
    end
  end

  describe "latest_prs/3" do
    test "builds a Finch request struct" do
      request = Client.latest_prs("TOKEN", "lorenzosinisi", "somerepo")

      body =
        "{\"query\":\"  query {\\n  repository(name: \\\"somerepo\\\", owner: \\\"lorenzosinisi\\\") {\\n    pullRequests(first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) {\\n      nodes {\\n        number\\n        title\\n        mergeable\\n        potentialMergeCommit {oid}\\n        headRefOid\\n        headRefName\\n        baseRefName\\n        reviews(states: [APPROVED, DISMISSED, CHANGES_REQUESTED], last: 1) {nodes {state}}\\n      }\\n    }\\n  }\\n}\\n\"}"

      assert %Finch.Request{
               body: body,
               headers: [{"Authorization", "bearer TOKEN"}],
               host: "api.github.com",
               method: "POST",
               path: "/graphql",
               port: 443,
               query: nil,
               scheme: :https
             } == request
    end
  end
end

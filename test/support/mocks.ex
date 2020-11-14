defmodule Github.HttpFakeClient do
  @moduledoc false
  @behaviour Github.Client.Http

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

  @impl Github.Client.Http
  def request(_headers, _body),
    do: {:ok, 200, Jason.encode!(@success_json)}
end

defmodule Github.HttpFakeClientError do
  @moduledoc false
  @behaviour Github.Client.Http

  @impl Github.Client.Http
  def request(_headers, _body), do: {:ok, 400, "something went wrong"}
end

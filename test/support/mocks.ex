defmodule Github.HttpFakeClient do
  @moduledoc "I am a mock"
  @behaviour Github.Client
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

  def api_post(_req) do
    {:ok, %{status: 200, body: Jason.encode!(@success_json)}}
  end

  def request(req, _), do: api_post(req)

  def build(_, _, _, _), do: %{}
end

defmodule Github.HttpFakeClientError do
  @moduledoc "I am a mock"
  @behaviour Github.Client
  @error_json {:error, %{status: 400, body: "something went wrong"}}
  def api_post(_req), do: @error_json
  def request(req, _), do: api_post(req)
  def build(_, _, _, _), do: %{}
end

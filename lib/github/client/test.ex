defmodule Github.Client.Test do
  @moduledoc """
  This module can be used when running your unit tests,
  it is not available in production
  """
  if Mix.env() == :test do
    @spec enable :: :ok
    def enable, do: :persistent_term.put(__MODULE__, true)

    @spec disable :: :ok
    def disable, do: :persistent_term.put(__MODULE__, false)

    @spec used? :: boolean
    def used?, do: :persistent_term.get(__MODULE__, false)

    @spec expect_latest_prs(String.t(), String.t(), Github.Client.Http.response()) :: :ok
    def expect_latest_prs(owner, repo, response) do
      request = Github.Client.latest_prs_query(owner, repo)
      Mox.expect(__MODULE__.Http, :request, fn _, ^request -> response end)
      :ok
    end

    @spec prs([map]) :: String.t()
    def prs(prs),
      do: Jason.encode!(%{"data" => %{"repository" => %{"pullRequests" => %{"nodes" => prs}}}})

    @spec pr :: map
    def pr do
      %{
        "baseRefName" => "master",
        "headRefName" => unique("source_branch"),
        "headRefOid" => unique_sha(),
        "mergeable" => "UNKNOWN",
        "number" => 5,
        "potentialMergeCommit" => unique_sha(),
        "reviews" => %{"nodes" => []},
        "title" => unique("title")
      }
    end

    defp unique_sha,
      do: :crypto.hash(:sha, :crypto.strong_rand_bytes(16)) |> Base.encode16(case: :lower)

    defp unique(data),
      do: "#{data}#{System.unique_integer([:monotonic, :positive])}"

    Mox.defmock(__MODULE__.Http, for: Github.Client.Http)
  else
    def used?, do: false
  end
end

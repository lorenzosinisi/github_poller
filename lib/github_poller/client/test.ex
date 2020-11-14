defmodule Github.Client.Test do
  def enable, do: :persistent_term.put(__MODULE__, true)
  def disable, do: :persistent_term.put(__MODULE__, false)
  def used?, do: :persistent_term.get(__MODULE__, false)

  def expect(response),
    do: Mox.expect(__MODULE__.Http, :request, fn _, _ -> response end)

  def prs(prs),
    do: Jason.encode!(%{"data" => %{"repository" => %{"pullRequests" => %{"nodes" => prs}}}})

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

  defp unique(title),
    do: "#{title}#{System.unique_integer([:monotonic, :positive])}"

  defp unique_sha,
    do: :crypto.hash(:sha, :crypto.strong_rand_bytes(16)) |> Base.encode16(case: :lower)

  Mox.defmock(__MODULE__.Http, for: Github.Client.Http)
end
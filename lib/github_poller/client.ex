defmodule GithubPoller.Client do
  @moduledoc "Wrapper around the HTTP client implemented to communicate with the Github APIs"
  @api_endpoint "https://api.github.com/graphql"

  @type token :: String.t()
  @type owner :: String.t()
  @type reponsitory :: String.t()

  defdelegate encode!(body), to: Jason
  defdelegate decode!(body), to: Jason
  defdelegate build(method, endpoint, headers, body), to: Finch
  defdelegate request(request, module), to: Finch

  @spec request(Finch.Request.t()) :: {:ok, map()} | {:error, any()}
  def request(request) do
    case request(request, __MODULE__) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, decode!(body)}

      anything ->
        anything
    end
  end

  @spec latest_prs(token(), owner(), reponsitory()) :: {:ok, map()} | {:error, any()}
  def latest_prs(token, owner, repository) when is_binary(token) do
    build(
      :post,
      @api_endpoint,
      [{"Authorization", "bearer #{token}"}],
      lastest_prs_query(owner, repository)
    )
    |> request()
  end

  defp lastest_prs_query(owner, repository) when is_binary(owner) and is_binary(repository) do
    encode!(%{
      "query" => """
        query {
        repository(name: \"#{repository}\", owner: \"#{owner}\") {
          pullRequests(first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) {
            nodes {
              number
              title
              mergeable
              potentialMergeCommit {oid}
              headRefOid
              headRefName
              baseRefName
              reviews(states: [APPROVED, DISMISSED, CHANGES_REQUESTED], last: 1) {nodes {state}}
            }
          }
        }
      }
      """
    })
  end
end

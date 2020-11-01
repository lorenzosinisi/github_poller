defmodule GithubPoller.Client do
  @moduledoc "Wrapper around the HTTP client implemented to communicate with the Github APIs"
  @api_endpoint "https://api.github.com/graphql"

  @type token :: String.t()
  @type owner :: String.t()
  @type reponsitory :: String.t()

  defdelegate encode!(body), to: Jason
  defdelegate decode!(body), to: Jason
  defdelegate build(method, endpoint, headers, body), to: Finch

  @spec request(Finch.Request.t(), atom()) :: {:ok, map()} | {:error, any()}
  def request(%Finch.Request{} = request, http_client_mod \\ Finch) do
    case http_client_mod.request(request, __MODULE__) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, decode!(body)}

      anything ->
        anything
    end
  end

  @spec latest_prs(token(), owner(), reponsitory()) :: Finch.Request.t()
  def latest_prs(token, owner, repository) when is_binary(token) do
    build(
      :post,
      @api_endpoint,
      [{"Authorization", "bearer #{token}"}],
      lastest_prs_query(owner, repository)
    )
  end

  defp lastest_prs_query(owner, repository) when is_binary(owner) and is_binary(repository) do
    encode!(%{
      "query" => """
        query {
        repository(name: #{inspect(repository)}, owner: #{inspect(owner)}) {
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

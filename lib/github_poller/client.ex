defmodule Github.Client do
  @moduledoc "Wrapper around the HTTP client implemented to communicate with the Github APIs"
  @api_endpoint "https://api.github.com/graphql"

  @type token :: String.t()
  @type owner :: String.t()
  @type reponsitory :: String.t()

  defdelegate encode!(body), to: Jason
  defdelegate decode!(body), to: Jason

  @spec request(map()) :: {:ok, map()} | {:error, any()}
  def request(%{} = request) do
    case http_client().request(request, __MODULE__) do
      {:ok, %{status: 200, body: body}} ->
        response = decode!(body)
        {:ok, get_in(response, ["data", "repository", "pullRequests", "nodes"])}

      anything ->
        anything
    end
  end

  @callback api_post(map()) :: {:ok, map()} | {:error, any()}
  def api_post(request) do
    http_client().request(request, __MODULE__)
  end

  def latest_prs(token, owner, repository) when is_binary(token) do
    client = http_client()
    headers = [{"Authorization", "bearer #{token}"}]
    body = lastest_prs_query(owner, repository)
    http_request = client.build(:post, @api_endpoint, headers, body)

    request(http_request)
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
              headRefOid
            }
          }
        }
      }
      """
    })
  end

  defp http_client do
    Application.fetch_env!(:github_poller, :http_client)
  end
end

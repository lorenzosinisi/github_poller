defmodule Github.Client do
  @moduledoc "Wrapper around the HTTP client implemented to communicate with the Github APIs"
  @type token :: String.t()
  @type owner :: String.t()
  @type reponsitory :: String.t()

  def latest_prs(token, owner, repository) when is_binary(token) do
    headers = [{"Authorization", "bearer #{token}"}]
    body = lastest_prs_query(owner, repository)

    case http_client().request(headers, body) do
      {:ok, 200, body} ->
        response = Jason.decode!(body)
        {:ok, get_in(response, ["data", "repository", "pullRequests", "nodes"])}

      {:ok, status, body} ->
        {:error, "#{status}:\n#{body}"}

      other ->
        other
    end
  end

  defp lastest_prs_query(owner, repository) when is_binary(owner) and is_binary(repository) do
    Jason.encode!(%{
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
    Application.get_env(:github_poller, :http_client, __MODULE__.HttpClient)
  end

  defmodule Http do
    @moduledoc false

    @callback request(headers :: [{String.t(), String.t()}], body :: String.t()) ::
                {:ok, status :: pos_integer, body :: String.t()}
                | {:error, any()}
  end

  defmodule Http.Real do
    @moduledoc false
    @behaviour Http

    @api_endpoint "https://api.github.com/graphql"

    @impl Http
    def request(headers, body) do
      req = Finch.build(:post, @api_endpoint, headers, body)

      with {:ok, response} <- Finch.request(req, Github.Client),
           do: {:ok, response.status, response.body}
    end
  end
end

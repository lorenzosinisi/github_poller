defmodule Github.Client do
  @moduledoc "Wrapper around the HTTP client implemented to communicate with the Github APIs"
  @type token :: String.t()
  @type owner :: String.t()
  @type reponsitory :: String.t()

  def latest_prs(token, owner, repository) when is_binary(token) do
    headers = [{"Authorization", "bearer #{token}"}]
    body = latest_prs_query(owner, repository)

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

  @doc false
  def latest_prs_query(owner, repository) do
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
    if Github.Client.Test.used?(), do: Github.Client.Test.Http, else: __MODULE__.Http.Real
  end

  defmodule Http do
    @moduledoc false

    @type headers :: [{String.t(), String.t()}]

    @type response ::
            {:ok, status :: pos_integer, body :: String.t()}
            | {:error, any()}

    @callback request(headers, payload :: String.t()) :: response
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

defmodule Github.ClientTest do
  use ExUnit.Case, async: true
  alias Github.Client

  describe "lastest_prs/2" do
    test "returns open pull requests on success" do
      pr1 = Client.Test.pr()
      pr2 = Client.Test.pr()

      Client.Test.expect_latest_prs(
        "some_owner",
        "some_repo",
        {:ok, 200, Client.Test.prs([pr1, pr2])}
      )

      assert Client.latest_prs("Token", "some_owner", "some_repo") == {:ok, [pr1, pr2]}
    end

    test "returns error if reponse status is not 200" do
      Client.Test.expect_latest_prs("some_owner", "some_repo", {:ok, 400, "something went wrong"})

      assert Client.latest_prs("Token", "some_owner", "some_repo") ==
               {:error, "400:\nsomething went wrong"}
    end

    test "returns client error" do
      Client.Test.expect_latest_prs("some_owner", "some_repo", {:error, :client_error})
      assert Client.latest_prs("Token", "some_owner", "some_repo") == {:error, :client_error}
    end
  end
end

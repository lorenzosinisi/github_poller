defmodule Github.ClientTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Github.Client
  doctest Github.Poller

  setup_all do
    Client.Test.enable()
    on_exit(&Client.Test.disable/0)
  end

  describe "lastest_prs/2" do
    test "returns open pull requests on success" do
      pr1 = Client.Test.pr()
      pr2 = Client.Test.pr()

      Client.Test.expect({:ok, 200, Client.Test.prs([pr1, pr2])})

      assert Client.latest_prs("Token", "some_owner", "some_repo") == {:ok, [pr1, pr2]}
    end

    test "returns error if reponse status is not 200" do
      Client.Test.expect({:ok, 400, "something went wrong"})

      assert Client.latest_prs("Token", "some_owner", "some_repo") ==
               {:error, "400:\nsomething went wrong"}
    end

    test "returns client error" do
      Client.Test.expect({:error, :client_error})
      assert Client.latest_prs("Token", "some_owner", "some_repo") == {:error, :client_error}
    end
  end
end

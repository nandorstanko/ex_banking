defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  describe "deposit/3" do
    test "reach max allowed operations" do
      ExBanking.create_user("user1")

      stream = 1..11 |> ParallelStream.map(fn x -> ExBanking.deposit("user1", x * 10, "HUF") end)

      results = stream |> Enum.into([])

      assert Enum.member?(results, {:error, :too_many_requests_to_user})
    end
  end
end

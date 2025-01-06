defmodule Wttj.CandidatesTest do
  use Wttj.DataCase

  alias Wttj.Candidates
  import Wttj.JobsFixtures

  setup do
    job1 = job_fixture()
    job2 = job_fixture()
    {:ok, job1: job1, job2: job2}
  end

  describe "candidates" do
    alias Wttj.Candidates.Candidate

    import Wttj.CandidatesFixtures

    @invalid_attrs %{position: nil, status: nil, email: nil}

    test "list_candidates/1 returns all candidates for a given job", %{job1: job1, job2: job2} do
      candidate1 = candidate_fixture(%{job_id: job1.id})
      _ = candidate_fixture(%{job_id: job2.id})
      assert Candidates.list_candidates(job1.id) == [candidate1]
    end

    test "create_candidate/1 with valid data creates a candidate", %{job1: job1} do
      email = unique_user_email()
      valid_attrs = %{email: email, position: 3, job_id: job1.id}
      assert {:ok, %Candidate{} = candidate} = Candidates.create_candidate(valid_attrs)
      assert candidate.email == email
      assert {:error, _} = Candidates.create_candidate()
    end

    test "update_candidate/2 with valid data updates the candidate", %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id})
      email = unique_user_email()
      update_attrs = %{position: 43, status: :rejected, email: email}

      assert {:ok, %Candidate{} = candidate} =
               Candidates.update_candidate(candidate, update_attrs)

      # position is evaluated to 0 since there is only one candidate if this test
      assert candidate.position == 0
      assert candidate.status == :rejected
      assert candidate.email == email
    end

    test "update_candidate/2 maintains correct position ordering when moving candidate up", %{
      job1: job1
    } do
      candidate1 = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate2 = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})
      candidate3 = candidate_fixture(%{job_id: job1.id, status: :new, position: 2})

      assert {:ok, candidate3} = Candidates.update_candidate(candidate3, %{position: 0})

      [first, second, third] =
        job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert first.id == candidate3.id
      assert first.position == 0
      assert second.id == candidate1.id
      assert second.position == 1
      assert third.id == candidate2.id
      assert third.position == 2
    end

    test "update_candidate/2 maintains correct position ordering when moving candidate down", %{
      job1: job1
    } do
      candidate1 = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate2 = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})
      candidate3 = candidate_fixture(%{job_id: job1.id, status: :new, position: 2})

      assert {:ok, candidate1} = Candidates.update_candidate(candidate1, %{position: 2})

      [first, second, third] =
        job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert first.id == candidate2.id
      assert first.position == 0
      assert second.id == candidate3.id
      assert second.position == 1
      assert third.id == candidate1.id
      assert third.position == 2
    end

    test "update_candidate/2 ajdust position ordering when moving candidate in between",
         %{
           job1: job1
         } do
      candidate1 = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate2 = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})
      candidate3 = candidate_fixture(%{job_id: job1.id, status: :new, position: 2})

      assert {:ok, candidate1} = Candidates.update_candidate(candidate1, %{position: 1})

      [first, second, third] =
        job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert first.id == candidate2.id
      assert first.position == 0
      assert second.id == candidate1.id
      assert second.position == 1
      assert third.id == candidate3.id
      assert third.position == 2
    end

    test "update_candidate/2 handles status changes and position", %{job1: job1} do
      candidate1 = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})

      candidate2 = candidate_fixture(%{job_id: job1.id, status: :interview, position: 0})
      candidate3 = candidate_fixture(%{job_id: job1.id, status: :interview, position: 1})

      assert {:ok, candidate1} =
               Candidates.update_candidate(candidate1, %{position: 1, status: :interview})

      [first, second, third] =
        job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert first.id == candidate2.id
      assert first.position == 0
      assert first.status == :interview

      assert second.id == candidate1.id
      assert second.position == 1
      assert second.status == :interview

      assert third.id == candidate3.id
      assert third.position == 2
      assert third.status == :interview
    end

    test "update_candidate/2 with out of bound position is adapting to existing number of candidates",
         %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})

      candidate_fixture(%{job_id: job1.id, status: :interview, position: 0})
      candidate_fixture(%{job_id: job1.id, status: :interview, position: 1})

      assert {:ok, %{position: 0}} =
               Candidates.update_candidate(candidate, %{status: :interview, position: -1})

      assert {:ok, %{position: 2}} =
               Candidates.update_candidate(candidate, %{status: :interview, position: 999})
    end

    test "update_candidate/2 with invalid data returns error changeset", %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id})
      assert {:error, %Ecto.Changeset{}} = Candidates.update_candidate(candidate, @invalid_attrs)
      assert candidate == Candidates.get_candidate!(job1.id, candidate.id)
    end

    test "change_candidate/1 returns a candidate changeset", %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id})
      assert %Ecto.Changeset{} = Candidates.change_candidate(candidate)
    end
  end
end

defmodule WttjWeb.CandidateControllerTest do
  use WttjWeb.ConnCase
  use WttjWeb.ChannelCase

  import Wttj.JobsFixtures
  import Wttj.CandidatesFixtures

  alias Wttj.Candidates.Candidate

  @update_attrs %{
    position: 43,
    status: :interview
  }
  @invalid_attrs %{position: nil, status: nil, email: nil}

  setup %{conn: conn} do
    job = job_fixture()
    {:ok, conn: put_req_header(conn, "accept", "application/json"), job: job}
  end

  describe "index" do
    test "lists all candidates", %{conn: conn, job: job} do
      conn = get(conn, ~p"/api/jobs/#{job}/candidates")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "update candidate" do
    setup [:create_candidate]

    test "renders candidate when data is valid", %{
      conn: conn,
      job: job,
      candidate: %Candidate{id: id} = candidate
    } do
      email = unique_user_email()
      attrs = Map.put(@update_attrs, :email, email)
      conn = put(conn, ~p"/api/jobs/#{job}/candidates/#{candidate}", candidate: attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/jobs/#{job}/candidates/#{id}")

      assert %{
               "id" => ^id,
               "email" => ^email,
               "position" => 0,
               "status" => "interview"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, candidate: candidate, job: job} do
      conn = put(conn, ~p"/api/jobs/#{job}/candidates/#{candidate}", candidate: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "broadcasts updated candidate", %{conn: conn, job: job} do
      candidate = candidate_fixture(%{job_id: job.id, status: :new, position: 0})

      # add other candidates to see correct position update
      candidate_fixture(%{job_id: job.id, status: :interview, position: 0})
      candidate_fixture(%{job_id: job.id, status: :interview, position: 1})

      job_id = candidate.job_id
      new_position = 1
      new_status = "interview"

      @endpoint.subscribe("candidates:#{job_id}")

      update_params = %{"position" => new_position, "status" => new_status}

      conn =
        patch(conn, ~p"/api/jobs/#{job_id}/candidates/#{candidate.id}", candidate: update_params)

      assert %{"data" => %{"id" => id, "position" => ^new_position, "status" => ^new_status}} =
               json_response(conn, 200)

      # converting to atom is necessary for comparison with the broadcasted data
      new_status = String.to_existing_atom(new_status)

      assert_broadcast "candidate_updated", %{
        id: ^id,
        position: ^new_position,
        status: ^new_status
      }
    end
  end

  defp create_candidate(%{job: job}) do
    candidate = candidate_fixture(%{job_id: job.id})
    %{candidate: candidate}
  end
end

defmodule WttjWeb.CandidateController do
  use WttjWeb, :controller

  alias Wttj.Candidates
  alias Wttj.Candidates.Candidate

  action_fallback WttjWeb.FallbackController

  @candidates_topic "candidates"
  @candidate_updated_event "candidate_updated"

  def index(conn, %{"job_id" => job_id}) do
    candidates = Candidates.list_candidates(job_id)
    render(conn, :index, candidates: candidates)
  end

  def show(conn, %{"job_id" => job_id, "id" => id}) do
    candidate = Candidates.get_candidate!(job_id, id)
    render(conn, :show, candidate: candidate)
  end

  def update(conn, %{"job_id" => job_id, "id" => id, "candidate" => candidate_params}) do
    candidate = Candidates.get_candidate!(job_id, id)

    with {:ok, %Candidate{} = candidate} <-
           Candidates.update_candidate(candidate, candidate_params) do
      WttjWeb.Endpoint.broadcast(
        "#{@candidates_topic}:#{job_id}",
        @candidate_updated_event,
        %{
          id: candidate.id,
          position: candidate.position,
          status: candidate.status
        }
      )

      render(conn, :show, candidate: candidate)
    end
  end
end

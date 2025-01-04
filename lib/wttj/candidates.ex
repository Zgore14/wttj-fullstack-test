defmodule Wttj.Candidates do
  @moduledoc """
  The Candidates context.
  """

  require Logger

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Wttj.Repo
  alias Wttj.Candidates.Candidate
  alias Wttj.Jobs

  @doc """
  Returns the list of candidates.

  ## Examples

      iex> list_candidates()
      [%Candidate{}, ...]

  """
  def list_candidates(job_id) do
    query = from c in Candidate, where: c.job_id == ^job_id
    Repo.all(query)
  end

  @doc """
  Gets a single candidate.

  Raises `Ecto.NoResultsError` if the Candidate does not exist.

  ## Examples

      iex> get_candidate!(123)
      %Candidate{}

      iex> get_candidate!(456)
      ** (Ecto.NoResultsError)

  """
  def get_candidate!(job_id, id), do: Repo.get_by!(Candidate, id: id, job_id: job_id)

  @doc """
  Creates a candidate.

  ## Examples

      iex> create_candidate(%{field: value})
      {:ok, %Candidate{}}

      iex> create_candidate(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_candidate(attrs \\ %{}) do
    %Candidate{}
    |> Candidate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a candidate.

  ## Examples

      iex> update_candidate(candidate, %{field: new_value})
      {:ok, %Candidate{}}

      iex> update_candidate(candidate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_candidate(%Candidate{} = candidate, attrs) do
    candidate_changeset = Candidate.changeset(candidate, attrs)

    if Changeset.changed?(candidate_changeset, :status) or
         Changeset.changed?(candidate_changeset, :position) do
      update_and_reorder_candidates(candidate, candidate_changeset)
    else
      Repo.update(candidate_changeset)
    end
  end

  defp update_and_reorder_candidates(candidate, candidate_changeset) do
    Logger.debug("Updating candidate #{candidate.id} with reordering")

    Repo.transaction(fn ->
      # reordering is done after the update, position is temporarily
      # set to -1 to avoid potential unique key constraint error
      case candidate_changeset |> Changeset.put_change(:position, -1) |> Repo.update() do
        {:ok, updated_candidate} ->
          handle_candidate_reordering!(
            updated_candidate,
            candidate,
            candidate_changeset
          )

          # getting the freshest version of the candidate after the reordering
          get_candidate!(candidate.job_id, updated_candidate.id)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking candidate changes.

  ## Examples

      iex> change_candidate(candidate)
      %Ecto.Changeset{data: %Candidate{}}

  """
  def change_candidate(%Candidate{} = candidate, attrs \\ %{}) do
    Candidate.changeset(candidate, attrs)
  end

  defp evaluate_new_position(%Ecto.Changeset{} = candidate_changeset) do
    status = Changeset.get_field(candidate_changeset, :status)
    job_id = Changeset.get_field(candidate_changeset, :job_id)
    max_position = Jobs.count_candidates(job_id, [status])

    # ensure that the new position is not greater than the max position and not less than 0
    new_position =
      candidate_changeset
      |> Changeset.get_field(:position)
      |> min(max_position)
      |> max(0)

    new_position
  end

  defp handle_candidate_reordering!(
         %Candidate{} = updated_candidate,
         %Candidate{} = candidate,
         candidate_changeset
       ) do
    new_position = evaluate_new_position(candidate_changeset)

    Logger.debug(
      "New candidate position `#{new_position}` for status `#{updated_candidate.status}`"
    )

    # we reorder candidates within the previous status only if the status has changed
    if Changeset.changed?(candidate_changeset, :status) do
      Logger.debug("Reordering candidates from previous status `#{candidate.status}`")
      reorder_candidates_and_update_positions!(candidate.job_id, candidate.status)
    end

    # we reorder candidates within the current status a after update if the status or position has changed
    Logger.debug("Reordering candidates on current status `#{updated_candidate.status}`")

    reorder_candidates_and_update_positions!(
      updated_candidate.job_id,
      updated_candidate.status,
      updated_candidate,
      new_position
    )
  end

  defp reorder_candidates_and_update_positions!(
         job_id,
         status,
         candidate_to_move \\ nil,
         new_position \\ nil
       ) do
    # Fetch all candidates in the specified job and status
    candidates =
      from(c in Candidate)
      |> where([c], c.job_id == ^job_id and c.status == ^status)
      |> exclude_updated_candidate(candidate_to_move)
      |> order_by([c], asc: c.position)
      |> Repo.all()

    # Insert the updated candidate if provided, at its position in the list
    candidates =
      if not is_nil(candidate_to_move) and not is_nil(new_position) do
        List.insert_at(candidates, new_position, candidate_to_move)
      else
        candidates
      end

    # Reorder positions
    candidates
    |> Enum.with_index()
    # Rejecting unchanged candidates to avoid useless update (except if it's the candidate to move)
    |> Enum.reject(fn {candidate, index} ->
      if is_nil(candidate_to_move) or candidate.id != candidate_to_move.id do
        candidate.position == index
      end
    end)
    |> Enum.map(fn {candidate, index} ->
      candidate
      |> Map.from_struct()
      |> Map.delete(:__meta__)
      |> Map.put(:position, index)
    end)
    |> then(
      &Repo.insert_all(Candidate, &1,
        on_conflict: {:replace, [:position]},
        conflict_target: [:id]
      )
    )
  end

  # Helper to exclude the updated candidate if provided
  defp exclude_updated_candidate(query, nil), do: query

  defp exclude_updated_candidate(query, %Candidate{id: id}) do
    where(query, [c], c.id != ^id)
  end
end

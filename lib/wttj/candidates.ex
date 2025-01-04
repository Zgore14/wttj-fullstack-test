defmodule Wttj.Candidates do
  @moduledoc """
  The Candidates context.
  """

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
    Repo.transaction(fn ->
      candidate_changeset =
        candidate
        |> Candidate.changeset(attrs)
        |> put_evaluated_position()

      IO.inspect(attrs, label: "REQUESTED CHANGES")

      # we reorder candidates within the previous status only if the status has changed
      if Changeset.changed?(candidate_changeset, :status) do
        reorder_candidates!(candidate.job_id, candidate.status)
      end

      # we reorder candidates within a after update if the status or position has changed
      if Changeset.changed?(candidate_changeset, :status) or
           Changeset.changed?(candidate_changeset, :position) do
        candidate_changeset
        |> Changeset.apply_changes()
        |> reorder_candidates!()
      end

      case Repo.update(candidate_changeset) do
        {:ok, updated_candidate} ->
          updated_candidate

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

  defp put_evaluated_position(%Ecto.Changeset{} = candidate_changeset) do
    status = Changeset.get_field(candidate_changeset, :status)
    job_id = Changeset.get_field(candidate_changeset, :job_id)
    IO.inspect(status, label: "STATUS")
    max_position = Jobs.count_candidates(job_id, [status])

    # ensure that the new position is not greater than the max position and not less than 0
    new_position =
      candidate_changeset |> Changeset.get_field(:position) |> min(max_position) |> max(0)

    Changeset.put_change(candidate_changeset, :position, new_position)
  end

  defp reorder_candidates!(%Candidate{} = candidate) do
    reorder_candidates!(candidate.job_id, candidate.status, candidate)
  end

  defp reorder_candidates!(job_id, status, moved_candidate \\ nil) do
    # Fetch all candidates in the specified job and status
    candidates =
      from(c in Candidate)
      |> where([c], c.job_id == ^job_id and c.status == ^status)
      |> exclude_updated_candidate(moved_candidate)
      |> order_by([c], asc: c.position)
      |> Repo.all()

    # Insert the updated candidate if provided, at its position in the list
    candidates =
      if not is_nil(moved_candidate) do
        List.insert_at(candidates, moved_candidate.position, moved_candidate)
      else
        candidates
      end

    # Reorder positions
    reorder_positions(candidates)
  end

  # Helper to exclude the updated candidate if provided
  defp exclude_updated_candidate(query, nil), do: query

  defp exclude_updated_candidate(query, %Candidate{id: id}) do
    where(query, [c], c.id != ^id)
  end

  defp reorder_positions(candidates) do
    candidates
    |> Enum.with_index()
    # Avoid updating unchanged candidates
    |> Enum.reject(fn {candidate, index} -> candidate.position == index end)
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
end

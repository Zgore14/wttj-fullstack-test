defmodule WttjWeb.CandidateChannel do
  @moduledoc false
  use WttjWeb, :channel

  @impl true
  def join("candidates:" <> _job_id, _params, socket) do
    {:ok, socket}
  end
end

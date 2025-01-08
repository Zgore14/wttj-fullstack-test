defmodule WttjWeb.CandidateChannelTest do
  use Wttj.DataCase
  use WttjWeb.ChannelCase

  import Wttj.JobsFixtures

  setup do
    job = job_fixture()

    {:ok, _, socket} =
      WttjWeb.UserSocket
      |> socket()
      |> subscribe_and_join(WttjWeb.CandidateChannel, "candidates:#{job.id}")

    %{socket: socket, job: job}
  end

  test "successfully joins candidate channel with job_id", %{socket: socket, job: job} do
    assert socket.topic == "candidates:#{job.id}"
    assert socket.joined
  end
end

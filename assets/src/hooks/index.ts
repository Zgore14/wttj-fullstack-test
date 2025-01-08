import { useMutation, useQuery, useQueryClient } from 'react-query'
import { useState, useContext, useEffect } from 'react'
import { getCandidates, getJob, getJobs, updateCandidate, CandidateParams } from '../api'
import { PhoenixSocketContext } from '../components/PhoenixSocketContext'
import { Channel, Socket } from 'phoenix'


export const useJobs = () => {
  const { isLoading, error, data } = useQuery({
    queryKey: ['jobs'],
    queryFn: getJobs,
  })

  return { isLoading, error, jobs: data }
}

export const useJob = (jobId?: string) => {
  const { isLoading, error, data } = useQuery({
    queryKey: ['job', jobId],
    queryFn: () => getJob(jobId),
    enabled: !!jobId,
  })

  return { isLoading, error, job: data }
}

export const useCandidates = (jobId?: string) => {
  const { isLoading, error, data } = useQuery({
    queryKey: ['candidates', jobId],
    queryFn: () => getCandidates(jobId),
    enabled: !!jobId,
  })

  return { isLoading, error, candidates: data }
}

export const useUpdateCandidate = (jobId?: string) => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ candidateId, candidate }: { candidateId: string, candidate: CandidateParams }) =>
      updateCandidate(jobId, candidateId, candidate),
    onSuccess: () => {
      // Invalidate and refetch candidates list after successful update
      queryClient.invalidateQueries(['candidates', jobId])
    }
  })
}

export const useChannel = (channelName: string) => {
  const [channel, setChannel] = useState<Channel>()
  const { socket } = useContext<{ socket: Socket | null }>(PhoenixSocketContext)

  useEffect(() => {
    if (!socket) return

    const phoenixChannel = socket.channel(channelName);

    phoenixChannel.join().receive('ok', () => {
      setChannel(phoenixChannel)
    })

    // leave the channel when the component unmounts
    return () => {
      phoenixChannel.leave()
    };
  }, [])
  // only connect to the channel once on component mount

  return [channel]
}
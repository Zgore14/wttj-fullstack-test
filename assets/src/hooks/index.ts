import { useMutation, useQuery, useQueryClient } from 'react-query'
import { getCandidates, getJob, getJobs, updateCandidate, CandidateParams} from '../api'

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
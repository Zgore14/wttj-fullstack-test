type Job = {
  id: string
  name: string
}

export enum CandidateStatusesEnum {
  'new',
  'interview',
  'hired',
  'rejected'
}

export type CandidateStatus = keyof typeof CandidateStatusesEnum

export type Candidate = {
  id: number
  email: string
  status: CandidateStatus
  position: number
}

export type CandidateParams = {
  id?: number
  email?: string
  status?: CandidateStatus
  position?: number
}

// TODO: Use Axios for API calls

export const getJobs = async (): Promise<Job[]> => {
  const response = await fetch(`http://localhost:4000/api/jobs`)
  const { data } = await response.json()
  return data
}

export const getJob = async (jobId?: string): Promise<Job | null> => {
  if (!jobId) return null
  const response = await fetch(`http://localhost:4000/api/jobs/${jobId}`)
  const { data } = await response.json()
  return data
}

export const getCandidates = async (jobId?: string): Promise<Candidate[]> => {
  if (!jobId) return []
  const response = await fetch(`http://localhost:4000/api/jobs/${jobId}/candidates`)
  const { data } = await response.json()
  return data
}

export const updateCandidate = async (jobId?: string, candidateId?: string, candidateParams?: CandidateParams): Promise<Candidate> => {
  const response = await fetch(`http://localhost:4000/api/jobs/${jobId}/candidates/${candidateId}`, {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json', // Ensure the server knows the content type
  },
  body: JSON.stringify({
    candidate: candidateParams
    })
  })
  const { data } = await response.json()
  return data
}

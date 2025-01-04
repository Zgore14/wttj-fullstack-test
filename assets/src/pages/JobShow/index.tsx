import { useParams } from 'react-router-dom'
import { useJob, useCandidates, useUpdateCandidate } from '../../hooks'
import { Text } from '@welcome-ui/text'
import { Flex } from '@welcome-ui/flex'
import { Box } from '@welcome-ui/box'
import { useEffect, useMemo } from 'react'
import { Candidate, CandidateStatus } from '../../api'
import CandidateCard from '../../components/Candidate'
import { Badge } from '@welcome-ui/badge'
import CandidateBox from '../../components/CandidateBox'
import { monitorForElements } from  '@atlaskit/pragmatic-drag-and-drop/element/adapter'

const COLUMNS: CandidateStatus[] = [
  'new',
  'interview',
  'hired',
  'rejected'
]

interface SortedCandidates {
  new?: Candidate[]
  interview?: Candidate[]
  hired?: Candidate[]
  rejected?: Candidate[]
}

function JobShow() {
  const { jobId } = useParams()
  const { job } = useJob(jobId)
  const { candidates } = useCandidates(jobId)
  const updateCandidateMutation = useUpdateCandidate(jobId)


  const sortedCandidates = useMemo(() => {
    if (!candidates) return {}

    return candidates.reduce<SortedCandidates>((acc, c: Candidate) => {
      acc[c.status] = [...(acc[c.status] || []), c].sort((a, b) => a.position - b.position)
      return acc
    }, {})
  }, [candidates])

  useEffect(() => {
    return monitorForElements({
        onDrop({ source, location }) {
          const destination = location.current.dropTargets[0];
     
          if (!destination) {
              // if dropped outside of any drop targets
              return;
          }

          const draggedCandidate: Candidate = source.data.candidate as Candidate;
          const newStatus: CandidateStatus = destination.data.statusColumn as CandidateStatus;

          if (!jobId) return
          if (!draggedCandidate) return

          // const candidate = updateCandidate(jobId, draggedCandidate.id.toString(), { status: newStatus })
          updateCandidateMutation.mutate({ candidateId: draggedCandidate.id.toString(), candidate: { status: newStatus, position: draggedCandidate.position} })
        },
    });
  }, [candidates, jobId, updateCandidateMutation]);

  return (
    <>
      <Box backgroundColor="neutral-70" p={20} alignItems="center">
        <Text variant="h5" color="white" m={0}>
          {job?.name}
        </Text>
      </Box>

      <Box p={20}>
        <Flex gap={10}>
          {COLUMNS.map(column => (
            <CandidateBox key={column} statusColumn={column} >
              <Flex
                p={10}
                borderBottom={1}
                borderColor="neutral-30"
                alignItems="center"
                justify="space-between"
              >
                <Text color="black" m={0} textTransform="capitalize">
                  {column}
                </Text>
                <Badge>{(sortedCandidates[column] || []).length}</Badge>
              </Flex>
              <Flex direction="column" p={10} pb={0}>
                {sortedCandidates[column]?.map((candidate: Candidate) => (
                  <CandidateCard candidate={candidate} key={candidate.id}/>
                ))}
              </Flex>
            </CandidateBox>
          ))}
        </Flex>
      </Box>
    </>
  )
}

export default JobShow

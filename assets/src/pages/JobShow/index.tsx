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
import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter'
import { Edge, extractClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';


const candidateColumns: CandidateStatus[] = [
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
        let newStatus: CandidateStatus;
        let newPosition: number;

        if (!jobId) return
        if (!draggedCandidate) return

        if ('columnId' in destination.data) {
          // candidate is being drag to a column
          newStatus = destination.data.columnId as CandidateStatus;
          newPosition = (sortedCandidates[newStatus] || []).length;

        } else {
          // candidate is being drag to a candidate

          const edge: Edge | null = extractClosestEdge(destination.data);
          if (edge !== 'top' && edge !== 'bottom') return

          newStatus = destination.data.status as CandidateStatus;
          newPosition = Math.max(destination.data.position as number + (edge === 'top' ? -1 : 1), 0);
        }

        updateCandidateMutation.mutate({ candidateId: draggedCandidate.id.toString(), candidate: { status: newStatus, position: newPosition } })
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
          {candidateColumns.map(column => (
            <CandidateBox key={column} columnId={column}>
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
                  <CandidateCard candidate={candidate} key={candidate.id} />
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

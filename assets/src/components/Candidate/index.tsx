import { Card } from '@welcome-ui/card'
import { Candidate } from '../../api'
import { useEffect, useRef, useState } from 'react'
import { draggable, dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter'
import { combine } from "@atlaskit/pragmatic-drag-and-drop/combine";
import { attachClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';


function CandidateCard({ candidate }: { candidate: Candidate }) {
  const ref = useRef(null);
  const [dragging, setDragging] = useState<boolean>(false);

  useEffect(() => {
    const candidateCard = ref.current;
    if (!candidateCard) return

    return combine(
      draggable({
        element: candidateCard,
        getInitialData: () => ({ candidate }),
        onDragStart: () => setDragging(true),
        onDrop: () => setDragging(false),
      }),
      dropTargetForElements({
        element: candidateCard,
        getData: ({ input, element }) => {
          return attachClosestEdge(candidate, {
            input: input,
            element: element,
            allowedEdges: ["top", "bottom"]
          })
        }
      })
    )

  }, [candidate]);

  return (
    <Card mb={10} ref={ref} opacity={dragging ? 0.4 : 1}>
      <Card.Body>
        {candidate.email}
      </Card.Body>
    </Card>
  )
}

export default CandidateCard

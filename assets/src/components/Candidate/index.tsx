import { Card } from '@welcome-ui/card'
import { Candidate } from '../../api'
import { useEffect, useRef, useState } from 'react'
import { draggable } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';

function CandidateCard({ candidate }: { candidate: Candidate }) {
  const ref = useRef(null);
  const [dragging, setDragging] = useState<boolean>(false);

  useEffect(() => {
    const candidateCard = ref.current;
    // console.log('here 1:', candidateCard)
    if (!candidateCard) return 
    // console.log('here 2:', candidateCard)

    return draggable({
        element: candidateCard,
        getInitialData: () => ({ candidate }),
        onDragStart: () => setDragging(true),
        onDrop: () => setDragging(false),
    })
  }, []);

  return (
    // TODO: replace hidden by a proper style change
    <Card mb={10} ref={ref} hidden={dragging}>
      <Card.Body>{candidate.email}</Card.Body>
    </Card>
  )
}

export default CandidateCard

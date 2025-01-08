import { Box } from '@welcome-ui/box'
import { useEffect, useRef, useState } from 'react'
import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter'
import { CandidateStatus } from '../../api'

function CandidateBox({ columnId, children }: { columnId: CandidateStatus, children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null)
  const [isDraggedOver, setIsDraggedOver] = useState(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return

    return dropTargetForElements({
      element: el,
      getData: () => ({ columnId }),
      onDragEnter: () => setIsDraggedOver(true),
      onDragLeave: () => setIsDraggedOver(false),
      onDrop: () => setIsDraggedOver(false),
    })
  }, [columnId])

  return (
    <Box
      w={300}
      border={1}
      backgroundColor={isDraggedOver ? "yellow-10" : "white"}
      borderColor={isDraggedOver ? "yellow-30" : "neutral-30"}
      borderRadius="md"
      overflow="hidden"
      ref={ref}
    >
      {children}
    </Box>
  )
}
export default CandidateBox

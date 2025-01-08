import { expect, test, afterEach } from 'vitest'
import { Candidate } from '../../api'
import { render } from '../../test-utils'
import { fireEvent } from '@testing-library/dom'
import { screen } from '@testing-library/react'
import CandidateCard from '../../components/Candidate'
import CandidateBox from '../../components/CandidateBox'

afterEach(async () => {
    // cleanup any pending drags
    fireEvent.dragEnd(window);
    fireEvent.pointerMove(window);

})

test('renders candidate box with candidate card inside', () => {
    const candidate: Candidate = { id: 10, email: 'test@example.com', position: 1, status: 'new' }
    const { getByText } = render(
        <CandidateBox columnId={candidate.status}>
            <CandidateCard candidate={candidate} />
        </CandidateBox>)
    expect(getByText('test@example.com')).toBeInTheDocument()
    expect(getByText('test@example.com')).toBeVisible()
})

// drag and drop with jsdom seems not working properly
// 
test.skip('drag and drop candidate card from a candidate box to another', async () => {
    const baseStatus = 'new'
    const candidate: Candidate = { id: 10, email: 'candidate_1@example.com', position: 0, status: baseStatus }

    const targetStatus = 'interview'
    const candidate2: Candidate = { id: 11, email: 'candidate_2@example.com', position: 0, status: targetStatus }

    render(
        <>
            <div data-testid={baseStatus}>
                <CandidateBox columnId={baseStatus}>
                    <CandidateCard candidate={candidate} />
                </CandidateBox >
            </div>

            <div data-testid={targetStatus}>
                <CandidateBox columnId={targetStatus}>
                    <CandidateCard candidate={candidate2} />
                </CandidateBox>
            </div>

        </>

    )

    const baseCandidateBox = screen.getByTestId(baseStatus)?.firstElementChild
    if (!baseCandidateBox) throw new Error('Base status CandidateBox not found')

    const targetCandidateBox = screen.getByTestId(targetStatus)?.firstElementChild
    if (!targetCandidateBox) throw new Error('Target status CandidateBox not found')


    expect(baseCandidateBox.childElementCount).toBe(1)
    expect(targetCandidateBox.childElementCount).toBe(1)

    const candidateCard = baseCandidateBox.firstElementChild
    if (!candidateCard) throw new Error('Draggable Candidate not found')



    fireEvent.dragStart(candidateCard)


    // Simulate drag over target
    fireEvent.dragEnter(targetCandidateBox)
    fireEvent.dragOver(targetCandidateBox)
    // Simulate drop
    fireEvent.drop(targetCandidateBox)


    fireEvent.dragLeave(targetCandidateBox)
    fireEvent.dragEnd(candidateCard)

    expect(targetCandidateBox.childElementCount).toBe(2)
})
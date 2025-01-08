import '@testing-library/jest-dom'
// since we are using jsdom for testing, we need to polyfill the drag and drop events
// see https://atlassian.design/components/pragmatic-drag-and-drop/optional-packages/unit-testing/about for more informations
import '@atlaskit/pragmatic-drag-and-drop-unit-testing/drag-event-polyfill'
import '@atlaskit/pragmatic-drag-and-drop-unit-testing/dom-rect-polyfill';

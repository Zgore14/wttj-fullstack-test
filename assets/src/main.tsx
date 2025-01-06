import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import { QueryClient, QueryClientProvider } from 'react-query'
import { PhoenixSocketProvider } from './components/PhoenixSocketContext'


const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <PhoenixSocketProvider>
        <App />
      </PhoenixSocketProvider>s
    </QueryClientProvider>
  </StrictMode>
)

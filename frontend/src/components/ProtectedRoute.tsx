import { Navigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

interface Props {
  children: React.ReactNode
  requireRole?: 'author'
}

export function ProtectedRoute({ children, requireRole }: Props) {
  const { user, role, loading } = useAuth()

  if (loading) {
    return <div className="flex items-center justify-center h-32 text-gray-400">Loading…</div>
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  if (requireRole && role !== requireRole) {
    return <Navigate to="/" replace />
  }

  return <>{children}</>
}

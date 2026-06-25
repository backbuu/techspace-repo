import { Link, useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/hooks/useAuth'

export function Header() {
  const { user, role } = useAuth()
  const navigate = useNavigate()

  async function handleSignOut() {
    await supabase.auth.signOut()
    navigate('/')
  }

  return (
    <header className="border-b border-gray-200 bg-white">
      <div className="mx-auto max-w-5xl px-4 py-4 flex items-center justify-between">
        <Link to="/" className="text-xl font-bold text-blue-600">
          TechSpace
        </Link>

        <nav className="flex items-center gap-4 text-sm">
          <Link to="/search" className="text-gray-600 hover:text-gray-900">
            Search
          </Link>
          {user ? (
            <>
              <Link to="/bookmarks" className="text-gray-600 hover:text-gray-900">
                Bookmarks
              </Link>
              {role === 'author' && (
                <Link
                  to="/dashboard"
                  className="text-gray-600 hover:text-gray-900"
                >
                  Dashboard
                </Link>
              )}
              <button
                onClick={handleSignOut}
                className="text-gray-600 hover:text-gray-900"
              >
                Sign out
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className="text-gray-600 hover:text-gray-900">
                Sign in
              </Link>
              <Link
                to="/signup"
                className="rounded-md bg-blue-600 px-3 py-1.5 text-white hover:bg-blue-700"
              >
                Sign up
              </Link>
            </>
          )}
        </nav>
      </div>
    </header>
  )
}

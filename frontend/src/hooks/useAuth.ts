import { useEffect, useState } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

interface AuthState {
  session: Session | null
  user: User | null
  role: 'reader' | 'author' | null
  loading: boolean
}

export function useAuth(): AuthState {
  const [state, setState] = useState<AuthState>({
    session: null,
    user: null,
    role: null,
    loading: true,
  })

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        fetchRole(session)
      } else {
        setState({ session: null, user: null, role: null, loading: false })
      }
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) {
        fetchRole(session)
      } else {
        setState({ session: null, user: null, role: null, loading: false })
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  async function fetchRole(session: Session) {
    const { data } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', session.user.id)
      .single()
    setState({
      session,
      user: session.user,
      role: (data?.role ?? 'reader') as 'reader' | 'author',
      loading: false,
    })
  }

  return state
}

export type AuthRole = 'author' | 'reader' | null

export interface User {
  id: string
  email: string
  role: AuthRole
}

export interface PostSummary {
  id: string
  title: string
  slug: string
  excerpt: string | null
  cover_image_url: string | null
  category: string | null
  tags: string[]
  reading_time_minutes: number | null
  created_at: string
}

export interface Post extends PostSummary {
  author_id: string
  content: string
  status: 'draft' | 'published'
  updated_at: string
}

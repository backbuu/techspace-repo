-- TechSpace — Supabase schema
-- Run in Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- ── Tables ──────────────────────────────────────────────────────

create table if not exists categories (
  id   uuid primary key default gen_random_uuid(),
  name text unique not null,
  slug text unique not null
);

create table if not exists posts (
  id                  uuid primary key default gen_random_uuid(),
  author_id           uuid references auth.users not null,
  title               text not null,
  slug                text unique not null,
  content             text not null,
  excerpt             text,
  cover_image_url     text,
  status              text not null default 'draft'
                        check (status in ('draft', 'published')),
  category            text,
  tags                text[] default '{}',
  search_vector       tsvector,
  reading_time_minutes int,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

-- ── Full-text search trigger ─────────────────────────────────────

create or replace function update_search_vector()
returns trigger language plpgsql as $$
begin
  new.search_vector :=
    to_tsvector('english',
      coalesce(new.title, '') || ' ' || coalesce(new.content, '')
    );
  return new;
end;
$$;

drop trigger if exists posts_search_vector_update on posts;
create trigger posts_search_vector_update
  before insert or update on posts
  for each row execute function update_search_vector();

create index if not exists posts_search_idx on posts using gin(search_vector);
create index if not exists posts_status_idx  on posts(status);
create index if not exists posts_author_idx  on posts(author_id);

-- ── Row-Level Security ───────────────────────────────────────────

alter table posts enable row level security;
alter table categories enable row level security;

-- Anyone can read published posts
create policy "public_read_published" on posts
  for select using (status = 'published');

-- Authors can read their own drafts
create policy "author_read_own" on posts
  for select using (auth.uid() = author_id);

-- Authors can insert their own posts
create policy "author_insert" on posts
  for insert with check (auth.uid() = author_id);

-- Authors can update their own posts
create policy "author_update" on posts
  for update using (auth.uid() = author_id);

-- Authors can delete their own posts
create policy "author_delete" on posts
  for delete using (auth.uid() = author_id);

-- Categories are public read-only
create policy "public_read_categories" on categories
  for select using (true);

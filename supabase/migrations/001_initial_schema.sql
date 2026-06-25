-- Run this in the Supabase SQL editor to set up the full Phase 1 schema.

-- ── Profiles ────────────────────────────────────────────────────
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique,
  bio text,
  avatar_url text,
  role text not null default 'reader' check (role in ('reader', 'author')),
  created_at timestamptz default now()
);
alter table profiles enable row level security;
create policy "public read profiles" on profiles for select using (true);
create policy "own write profiles" on profiles for all using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function handle_new_user() returns trigger as $$
begin
  insert into profiles (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── Categories ──────────────────────────────────────────────────
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  slug text unique not null,
  description text
);
alter table categories enable row level security;
create policy "public read categories" on categories for select using (true);

-- ── Posts ───────────────────────────────────────────────────────
create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references auth.users not null,
  category_id uuid references categories,
  title text not null,
  slug text unique not null,
  excerpt text,
  content text not null,
  cover_image_url text,
  status text not null default 'draft' check (status in ('draft', 'published')),
  reading_time_minutes int,
  published_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  search_vector tsvector
);
alter table posts enable row level security;
create policy "public read published posts" on posts for select using (status = 'published');
create policy "author own posts" on posts for all using (auth.uid() = author_id);

-- Auto-update search_vector and updated_at
create or replace function posts_search_vector_update() returns trigger as $$
begin
  new.search_vector := to_tsvector('english',
    coalesce(new.title, '') || ' ' ||
    coalesce(new.excerpt, '') || ' ' ||
    coalesce(new.content, '')
  );
  new.updated_at := now();
  new.reading_time_minutes := greatest(1, ceil(
    array_length(string_to_array(trim(coalesce(new.content, '')), ' '), 1)::float / 200
  )::int);
  return new;
end;
$$ language plpgsql;

create trigger posts_search_vector_trigger
  before insert or update on posts
  for each row execute function posts_search_vector_update();

create index if not exists posts_search_idx on posts using gin(search_vector);
create index if not exists posts_status_idx on posts (status, published_at desc);

-- ── Tags ────────────────────────────────────────────────────────
create table if not exists tags (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  slug text unique not null
);
alter table tags enable row level security;
create policy "public read tags" on tags for select using (true);

-- ── Post ↔ Tag junction ─────────────────────────────────────────
create table if not exists post_tags (
  post_id uuid references posts on delete cascade,
  tag_id uuid references tags on delete cascade,
  primary key (post_id, tag_id)
);
alter table post_tags enable row level security;
create policy "public read post_tags" on post_tags for select using (true);
create policy "author write post_tags" on post_tags for all
  using (exists (select 1 from posts where id = post_id and author_id = auth.uid()));

-- ── Bookmarks ───────────────────────────────────────────────────
create table if not exists bookmarks (
  user_id uuid references auth.users on delete cascade,
  post_id uuid references posts on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, post_id)
);
alter table bookmarks enable row level security;
create policy "own bookmarks" on bookmarks for all using (auth.uid() = user_id);

-- ── Reading history ─────────────────────────────────────────────
create table if not exists reading_history (
  user_id uuid references auth.users on delete cascade,
  post_id uuid references posts on delete cascade,
  last_read_at timestamptz default now(),
  primary key (user_id, post_id)
);
alter table reading_history enable row level security;
create policy "own reading_history" on reading_history for all using (auth.uid() = user_id);

-- ── Storage bucket for cover images ─────────────────────────────
-- Run manually in Supabase dashboard: create a public bucket named "covers"
-- insert into storage.buckets (id, name, public) values ('covers', 'covers', true);

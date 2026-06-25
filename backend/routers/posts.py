import os
from typing import Optional
from fastapi import APIRouter, HTTPException
from supabase import create_client, Client
from models.post import PostSummary, Post

router = APIRouter()

_supabase: Optional[Client] = None


def _client() -> Client:
    global _supabase
    if _supabase is None:
        url = os.getenv("SUPABASE_URL", "")
        key = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
        _supabase = create_client(url, key)
    return _supabase


@router.get("", response_model=list[PostSummary])
def list_posts():
    client = _client()
    res = (
        client.table("posts")
        .select("id,title,slug,excerpt,cover_image_url,category,tags,reading_time_minutes,created_at")
        .eq("status", "published")
        .order("created_at", desc=True)
        .execute()
    )
    return res.data or []


@router.get("/{slug}", response_model=Post)
def get_post(slug: str):
    client = _client()
    res = (
        client.table("posts")
        .select("*")
        .eq("slug", slug)
        .eq("status", "published")
        .single()
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="Post not found")
    return res.data

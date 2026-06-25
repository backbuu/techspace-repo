from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class PostSummary(BaseModel):
    id: str
    title: str
    slug: str
    excerpt: Optional[str] = None
    cover_image_url: Optional[str] = None
    category: Optional[str] = None
    tags: List[str] = []
    reading_time_minutes: Optional[int] = None
    created_at: datetime


class Post(PostSummary):
    author_id: str
    content: str
    status: str
    updated_at: datetime

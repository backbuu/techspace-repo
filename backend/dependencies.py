from fastapi import Depends, HTTPException, status
from auth import get_current_user


def require_author(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "author":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Author role required")
    return user


def require_reader(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") not in ("reader", "author"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Reader role required")
    return user

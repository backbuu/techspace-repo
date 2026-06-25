from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from supabase import create_client
from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

bearer = HTTPBearer(auto_error=False)

# Supabase signs JWTs with the service role secret — fetch it from the JWT itself
# using the public JWKS or simply decode without verification of signature for
# the payload, then re-verify via Supabase's admin API. For simplicity we decode
# using the service role key as the HS256 secret (Supabase default behaviour).
SUPABASE_JWT_SECRET = SUPABASE_SERVICE_ROLE_KEY


def _supabase_admin():
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
) -> dict:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    token = credentials.credentials
    try:
        # Supabase JWTs are HS256 signed with the JWT secret (not the service role key).
        # We verify via the Supabase admin API to avoid hardcoding the JWT secret.
        admin = _supabase_admin()
        user = admin.auth.get_user(token)
        if user is None or user.user is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
        u = user.user
        # Fetch role from profiles table
        res = admin.table("profiles").select("role").eq("id", str(u.id)).single().execute()
        role = res.data["role"] if res.data else "reader"
        return {"id": str(u.id), "email": u.email, "role": role}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")


def require_author(user: dict = Depends(get_current_user)) -> dict:
    if user["role"] != "author":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Author role required")
    return user

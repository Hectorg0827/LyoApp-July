# Core utilities and helper functions
import asyncio
import hashlib
import secrets
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, TypeVar
from uuid import uuid4

import httpx
from pydantic import BaseModel

T = TypeVar('T')


def generate_id() -> str:
    """Generate unique ID"""
    return str(uuid4())


def generate_secure_token(length: int = 32) -> str:
    """Generate cryptographically secure token"""
    return secrets.token_urlsafe(length)


def hash_string(value: str) -> str:
    """Hash string using SHA-256"""
    return hashlib.sha256(value.encode()).hexdigest()


def utc_now() -> datetime:
    """Get current UTC datetime"""
    return datetime.now(timezone.utc)


def to_dict(obj: Any) -> Dict[str, Any]:
    """Convert object to dictionary"""
    if isinstance(obj, dict):
        return obj
    elif isinstance(obj, BaseModel):
        return obj.model_dump()
    elif hasattr(obj, '__dict__'):
        return obj.__dict__
    else:
        return {'value': obj}


def paginate_query(
    items: List[T],
    page: int = 1,
    page_size: int = 20,
    max_page_size: int = 100
) -> Dict[str, Any]:
    """Paginate list of items"""
    page_size = min(page_size, max_page_size)
    start_idx = (page - 1) * page_size
    end_idx = start_idx + page_size
    
    paginated_items = items[start_idx:end_idx]
    total_items = len(items)
    total_pages = (total_items + page_size - 1) // page_size
    
    return {
        'items': paginated_items,
        'pagination': {
            'page': page,
            'page_size': page_size,
            'total_items': total_items,
            'total_pages': total_pages,
            'has_next': page < total_pages,
            'has_prev': page > 1,
        }
    }


async def make_http_request(
    method: str,
    url: str,
    headers: Optional[Dict[str, str]] = None,
    json_data: Optional[Dict[str, Any]] = None,
    timeout: int = 30
) -> Dict[str, Any]:
    """Make HTTP request with error handling"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.request(
                method=method,
                url=url,
                headers=headers,
                json=json_data,
                timeout=timeout
            )
            response.raise_for_status()
            return {
                'success': True,
                'data': response.json() if response.content else {},
                'status_code': response.status_code
            }
        except httpx.HTTPStatusError as e:
            return {
                'success': False,
                'error': f"HTTP {e.response.status_code}: {e.response.text}",
                'status_code': e.response.status_code
            }
        except httpx.RequestError as e:
            return {
                'success': False,
                'error': f"Request error: {str(e)}",
                'status_code': 0
            }


def sanitize_filename(filename: str) -> str:
    """Sanitize filename for safe storage"""
    import re
    # Remove or replace unsafe characters
    filename = re.sub(r'[^\w\s\-_\.]', '', filename)
    filename = re.sub(r'\s+', '_', filename)
    return filename.strip('.')


def calculate_file_hash(content: bytes) -> str:
    """Calculate SHA-256 hash of file content"""
    return hashlib.sha256(content).hexdigest()


def format_file_size(size_bytes: int) -> str:
    """Format file size in human readable format"""
    if size_bytes == 0:
        return "0 B"
    
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    size = size_bytes
    
    while size >= 1024 and i < len(size_names) - 1:
        size /= 1024.0
        i += 1
    
    return f"{size:.1f} {size_names[i]}"


def validate_email(email: str) -> bool:
    """Basic email validation"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def clean_text(text: str, max_length: Optional[int] = None) -> str:
    """Clean and validate text content"""
    # Remove extra whitespace
    cleaned = ' '.join(text.split())
    
    # Truncate if needed
    if max_length and len(cleaned) > max_length:
        cleaned = cleaned[:max_length].rstrip() + '...'
    
    return cleaned


def extract_hashtags(text: str) -> List[str]:
    """Extract hashtags from text"""
    import re
    return re.findall(r'#\w+', text.lower())


def extract_mentions(text: str) -> List[str]:
    """Extract mentions from text"""
    import re
    return re.findall(r'@\w+', text.lower())


class AsyncBatch:
    """Utility for batching async operations"""
    
    def __init__(self, batch_size: int = 10, delay: float = 0.1):
        self.batch_size = batch_size
        self.delay = delay
    
    async def process(self, items: List[Any], processor) -> List[Any]:
        """Process items in batches"""
        results = []
        
        for i in range(0, len(items), self.batch_size):
            batch = items[i:i + self.batch_size]
            batch_tasks = [processor(item) for item in batch]
            batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)
            results.extend(batch_results)
            
            # Add delay between batches to avoid overwhelming services
            if i + self.batch_size < len(items):
                await asyncio.sleep(self.delay)
        
        return results


def create_cursor(timestamp: datetime, id: str) -> str:
    """Create pagination cursor"""
    import base64
    cursor_data = f"{timestamp.isoformat()}:{id}"
    return base64.urlsafe_b64encode(cursor_data.encode()).decode()


def parse_cursor(cursor: str) -> tuple[datetime, str]:
    """Parse pagination cursor"""
    import base64
    try:
        cursor_data = base64.urlsafe_b64decode(cursor.encode()).decode()
        timestamp_str, id_str = cursor_data.split(':', 1)
        timestamp = datetime.fromisoformat(timestamp_str)
        return timestamp, id_str
    except Exception:
        raise ValueError("Invalid cursor format")


def mask_sensitive_data(data: Dict[str, Any], fields: List[str]) -> Dict[str, Any]:
    """Mask sensitive fields in data"""
    masked = data.copy()
    for field in fields:
        if field in masked:
            if isinstance(masked[field], str) and len(masked[field]) > 4:
                masked[field] = masked[field][:2] + '*' * (len(masked[field]) - 4) + masked[field][-2:]
            else:
                masked[field] = '[MASKED]'
    return masked

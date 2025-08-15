# Redis Configuration and Connection Management
import json
import logging
from contextlib import asynccontextmanager
from typing import Any, AsyncGenerator, Dict, List, Optional, Union

import redis.asyncio as redis
from redis.asyncio import ConnectionPool

from .config import get_settings
from .logging import get_structured_logger

logger = get_structured_logger(__name__)

# Global Redis connection pool
_redis_pool: Optional[ConnectionPool] = None
_redis_client: Optional[redis.Redis] = None


async def init_redis() -> None:
    """Initialize Redis connection pool"""
    global _redis_pool, _redis_client
    
    settings = get_settings()
    
    _redis_pool = ConnectionPool.from_url(
        settings.redis_url,
        encoding="utf-8",
        decode_responses=True,
        max_connections=20,
    )
    
    _redis_client = redis.Redis(connection_pool=_redis_pool)
    
    # Test connection
    try:
        await _redis_client.ping()
        logger.info("Redis initialized successfully")
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        raise


async def close_redis() -> None:
    """Close Redis connections"""
    global _redis_pool, _redis_client
    
    if _redis_client:
        await _redis_client.aclose()
    
    if _redis_pool:
        await _redis_pool.aclose()
    
    logger.info("Redis connections closed")


def get_redis() -> redis.Redis:
    """Get Redis client instance"""
    if not _redis_client:
        raise RuntimeError("Redis not initialized. Call init_redis() first.")
    return _redis_client


async def check_redis_health() -> bool:
    """Check Redis connectivity"""
    try:
        if not _redis_client:
            return False
        
        await _redis_client.ping()
        return True
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")
        return False


# Rate limiting utilities
class RateLimiter:
    """Redis-based rate limiter"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    async def is_rate_limited(
        self, 
        key: str, 
        limit: int, 
        window: int = 60,
        increment: int = 1
    ) -> tuple[bool, int]:
        """
        Check if rate limit is exceeded.
        
        Args:
            key: Rate limit key (e.g., "auth:user_id")
            limit: Maximum requests allowed
            window: Time window in seconds
            increment: Amount to increment by
            
        Returns:
            Tuple of (is_limited, current_count)
        """
        try:
            pipe = self.redis.pipeline()
            pipe.incr(key, increment)
            pipe.expire(key, window)
            results = await pipe.execute()
            
            current = int(results[0])
            is_limited = current > limit
            
            return is_limited, current
        except Exception as e:
            logger.error(f"Rate limiter error: {e}")
            return False, 0  # Fail open
    
    async def reset_rate_limit(self, key: str) -> None:
        """Reset rate limit for a key"""
        await self.redis.delete(key)


# Caching utilities
class RedisCache:
    """Redis-based caching utility"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    async def get(self, key: str, default: Any = None) -> Any:
        """Get value from cache"""
        try:
            value = await self.redis.get(key)
            if value is None:
                return default
            return json.loads(value)
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return default
    
    async def set(
        self, 
        key: str, 
        value: Any, 
        ttl: Optional[int] = None
    ) -> bool:
        """Set value in cache"""
        try:
            serialized = json.dumps(value, default=str)
            if ttl:
                return await self.redis.setex(key, ttl, serialized)
            else:
                return await self.redis.set(key, serialized)
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete value from cache"""
        try:
            return await self.redis.delete(key) > 0
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """Check if key exists in cache"""
        try:
            return await self.redis.exists(key) > 0
        except Exception as e:
            logger.error(f"Cache exists error for key {key}: {e}")
            return False
    
    async def increment(self, key: str, amount: int = 1) -> int:
        """Increment numeric value"""
        try:
            return await self.redis.incr(key, amount)
        except Exception as e:
            logger.error(f"Cache increment error for key {key}: {e}")
            return 0


# Pub/Sub utilities
class RedisPubSub:
    """Redis Pub/Sub utility for real-time messaging"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    async def publish(self, channel: str, message: Dict[str, Any]) -> int:
        """Publish message to channel"""
        try:
            serialized = json.dumps(message, default=str)
            return await self.redis.publish(channel, serialized)
        except Exception as e:
            logger.error(f"Pub/Sub publish error for channel {channel}: {e}")
            return 0
    
    @asynccontextmanager
    async def subscribe(self, *channels: str) -> AsyncGenerator[Any, None]:
        """Subscribe to channels"""
        pubsub = self.redis.pubsub()
        try:
            await pubsub.subscribe(*channels)
            yield pubsub
        finally:
            await pubsub.unsubscribe(*channels)
            await pubsub.aclose()


# WebSocket connection management
class WebSocketManager:
    """Manage WebSocket connections with Redis backing"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.connections: Dict[str, List[Any]] = {}  # user_id -> websockets
    
    async def add_connection(self, user_id: str, websocket: Any) -> None:
        """Add WebSocket connection"""
        if user_id not in self.connections:
            self.connections[user_id] = []
        
        self.connections[user_id].append(websocket)
        
        # Track connection in Redis
        await self.redis.sadd(f"ws:active_users", user_id)
        await self.redis.incr(f"ws:connections:{user_id}")
    
    async def remove_connection(self, user_id: str, websocket: Any) -> None:
        """Remove WebSocket connection"""
        if user_id in self.connections:
            try:
                self.connections[user_id].remove(websocket)
                if not self.connections[user_id]:
                    del self.connections[user_id]
                    await self.redis.srem(f"ws:active_users", user_id)
                
                await self.redis.decr(f"ws:connections:{user_id}")
            except ValueError:
                pass
    
    async def send_to_user(self, user_id: str, message: Dict[str, Any]) -> int:
        """Send message to all user connections"""
        if user_id not in self.connections:
            return 0
        
        sent = 0
        message_str = json.dumps(message, default=str)
        
        # Send to local connections
        for websocket in self.connections[user_id][:]:  # Copy list to avoid modification issues
            try:
                await websocket.send_text(message_str)
                sent += 1
            except Exception:
                # Remove dead connection
                await self.remove_connection(user_id, websocket)
        
        return sent
    
    async def broadcast_to_channel(self, channel: str, message: Dict[str, Any]) -> None:
        """Broadcast message via Redis Pub/Sub"""
        pubsub = RedisPubSub(self.redis)
        await pubsub.publish(f"ws:{channel}", message)
    
    async def get_active_users(self) -> List[str]:
        """Get list of active users"""
        try:
            return await self.redis.smembers("ws:active_users")
        except Exception:
            return []


# Utility functions
async def get_rate_limiter() -> RateLimiter:
    """Get rate limiter instance"""
    return RateLimiter(get_redis())


async def get_cache() -> RedisCache:
    """Get cache instance"""
    return RedisCache(get_redis())


async def get_pubsub() -> RedisPubSub:
    """Get pub/sub instance"""
    return RedisPubSub(get_redis())


async def get_websocket_manager() -> WebSocketManager:
    """Get WebSocket manager instance"""
    return WebSocketManager(get_redis())

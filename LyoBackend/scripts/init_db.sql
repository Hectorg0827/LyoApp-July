-- Initialize database with required extensions and settings
-- This file is run automatically when the PostgreSQL container starts

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Create database if it doesn't exist (already created by POSTGRES_DB)
-- Additional setup can go here

-- Set timezone
ALTER DATABASE lyoapp_dev SET timezone TO 'UTC';

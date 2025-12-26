-- Add missing enum value for devotional bookmarks.
-- NOTE: ALTER TYPE cannot run inside a transaction block.
ALTER TYPE public.bookmark_types ADD VALUE IF NOT EXISTS 'devotional';

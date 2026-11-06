-- ═══════════════════════════════════════════════════════════
-- Meva HUD — Hardened Supabase Database Schema (v4 Security Patch)
-- ═══════════════════════════════════════════════════════════

-- ── 1. Profiles ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT UNIQUE NOT NULL CHECK (char_length(username) BETWEEN 2 AND 32),
  avatar_url  TEXT CHECK (avatar_url IS NULL OR avatar_url ~ '^https://'),
  status      TEXT NOT NULL DEFAULT 'online'
                CHECK (status IN ('online', 'in-game', 'idle', 'dnd', 'offline')),
  activity    TEXT CHECK (activity IS NULL OR char_length(activity) <= 120),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles: authenticated read"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Profiles: owner update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup (hardened search_path)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    NEW.id,
    LEFT(COALESCE(NULLIF(BTRIM(NEW.raw_user_meta_data->>'username'), ''), 'ghost_' || LEFT(NEW.id::text, 8)), 32),
    CASE
      WHEN (NEW.raw_user_meta_data->>'avatar_url') ~ '^https://' THEN NEW.raw_user_meta_data->>'avatar_url'
      ELSE NULL
    END
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- ── 2. Friendships (Arkadaşlık Sistemi) ─────────────────

CREATE TABLE IF NOT EXISTS public.friendships (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT friendships_no_self_friend CHECK (user_id <> friend_id),
  UNIQUE(user_id, friend_id)
);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Friendships: read own"
  ON public.friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Friendships: insert pending request"
  ON public.friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id AND user_id <> friend_id AND status = 'pending');

-- Only the recipient (friend_id) may accept; either party may block
CREATE POLICY "Friendships: recipient update status"
  ON public.friendships FOR UPDATE
  USING (auth.uid() = friend_id OR auth.uid() = user_id)
  WITH CHECK (
    (auth.uid() = friend_id AND status IN ('accepted', 'blocked'))
    OR (auth.uid() = user_id AND status = 'blocked')
  );

CREATE POLICY "Friendships: delete"
  ON public.friendships FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);


-- ── 3. Direct Messages (Birebir Özel Mesajlaşma) ────────

CREATE TABLE IF NOT EXISTS public.direct_messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content      TEXT NOT NULL CHECK (char_length(BTRIM(content)) BETWEEN 1 AND 2000),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_direct_messages_pair
  ON public.direct_messages (sender_id, recipient_id, created_at DESC);

ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "DMs: read own"
  ON public.direct_messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

CREATE POLICY "DMs: insert own"
  ON public.direct_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id AND sender_id <> recipient_id);


-- ── 4. Servers & Server Members ─────────────────────────

CREATE TABLE IF NOT EXISTS public.servers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL CHECK (char_length(BTRIM(name)) BETWEEN 2 AND 64),
  icon_url    TEXT CHECK (icon_url IS NULL OR icon_url ~ '^https://'),
  owner_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.server_members (
  server_id  UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'member'
               CHECK (role IN ('owner', 'admin', 'member')),
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (server_id, user_id)
);

-- Non-recursive membership helper (prevents RLS infinite recursion)
CREATE OR REPLACE FUNCTION public.is_server_member(_server_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.server_members
    WHERE server_id = _server_id
      AND user_id = auth.uid()
  );
$$;

ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Servers: member read"
  ON public.servers FOR SELECT
  USING (owner_id = auth.uid() OR public.is_server_member(id));

CREATE POLICY "Servers: authenticated create"
  ON public.servers FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Servers: owner update"
  ON public.servers FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Members: member read"
  ON public.server_members FOR SELECT
  USING (public.is_server_member(server_id));

-- Prevent privilege escalation: self-joins can only have role = 'member'
CREATE POLICY "Members: self join as member"
  ON public.server_members FOR INSERT
  WITH CHECK (auth.uid() = user_id AND role = 'member');

CREATE OR REPLACE FUNCTION public.handle_new_server()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.server_members (server_id, user_id, role)
  VALUES (NEW.id, NEW.owner_id, 'owner');
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_server_created
  AFTER INSERT ON public.servers
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_server();


-- ── 5. Channel Categories & Channels ────────────────────

CREATE TABLE IF NOT EXISTS public.channel_categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id  UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  name       TEXT NOT NULL CHECK (char_length(BTRIM(name)) BETWEEN 1 AND 48),
  position   INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.channel_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories: member read"
  ON public.channel_categories FOR SELECT
  USING (public.is_server_member(server_id));

CREATE TABLE IF NOT EXISTS public.channels (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id   UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.channel_categories(id) ON DELETE SET NULL,
  name        TEXT NOT NULL CHECK (char_length(BTRIM(name)) BETWEEN 1 AND 48),
  type        TEXT NOT NULL DEFAULT 'text'
                CHECK (type IN ('text', 'voice')),
  position    INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Channels: member read"
  ON public.channels FOR SELECT
  USING (public.is_server_member(server_id));


-- ── 6. Messages ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content    TEXT NOT NULL CHECK (char_length(BTRIM(content)) BETWEEN 1 AND 2000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_channel_created
  ON public.messages (channel_id, created_at DESC);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Messages: member read"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.channels c
      WHERE c.id = messages.channel_id
        AND public.is_server_member(c.server_id)
    )
  );

CREATE POLICY "Messages: member insert"
  ON public.messages FOR INSERT
  WITH CHECK (
    auth.uid() = author_id
    AND EXISTS (
      SELECT 1 FROM public.channels c
      WHERE c.id = messages.channel_id
        AND public.is_server_member(c.server_id)
    )
  );

-- ── Enable Realtime for Live Chat & Direct Messages ─────
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;

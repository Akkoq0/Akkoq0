-- ═══════════════════════════════════════════════════════════
-- GhostLink — Supabase Database Schema (v3 with Friends & DMs)
-- ═══════════════════════════════════════════════════════════

-- ── 1. Profiles ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT UNIQUE NOT NULL,
  avatar_url  TEXT,
  status      TEXT NOT NULL DEFAULT 'online'
                CHECK (status IN ('online', 'in-game', 'idle', 'dnd', 'offline')),
  activity    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles: public read"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Profiles: owner update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'ghost_' || LEFT(NEW.id::text, 8)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
  UNIQUE(user_id, friend_id)
);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Friendships: read own"
  ON public.friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Friendships: insert request"
  ON public.friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Friendships: update status"
  ON public.friendships FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Friendships: delete"
  ON public.friendships FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);


-- ── 3. Direct Messages (Birebir Özel Mesajlaşma) ────────

CREATE TABLE IF NOT EXISTS public.direct_messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content      TEXT NOT NULL CHECK (char_length(content) <= 2000),
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
  WITH CHECK (auth.uid() = sender_id);


-- ── 4. Servers ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.servers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  icon_url    TEXT,
  owner_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Servers: member read"
  ON public.servers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.server_members
      WHERE server_members.server_id = servers.id
        AND server_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Servers: authenticated create"
  ON public.servers FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Servers: owner update"
  ON public.servers FOR UPDATE
  USING (auth.uid() = owner_id);


-- ── 5. Server Members ───────────────────────────────────

CREATE TABLE IF NOT EXISTS public.server_members (
  server_id  UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'member'
               CHECK (role IN ('owner', 'admin', 'member')),
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (server_id, user_id)
);

ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members: member read"
  ON public.server_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.server_members sm
      WHERE sm.server_id = server_members.server_id
        AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Members: self join"
  ON public.server_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_new_server()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.server_members (server_id, user_id, role)
  VALUES (NEW.id, NEW.owner_id, 'owner');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_server_created
  AFTER INSERT ON public.servers
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_server();


-- ── 6. Channel Categories & Channels ────────────────────

CREATE TABLE IF NOT EXISTS public.channel_categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id  UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  position   INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.channel_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories: member read"
  ON public.channel_categories FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.server_members
      WHERE server_members.server_id = channel_categories.server_id
        AND server_members.user_id = auth.uid()
    )
  );

CREATE TABLE IF NOT EXISTS public.channels (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id   UUID NOT NULL REFERENCES public.servers(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.channel_categories(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'text'
                CHECK (type IN ('text', 'voice')),
  position    INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Channels: member read"
  ON public.channels FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.server_members
      WHERE server_members.server_id = channels.server_id
        AND server_members.user_id = auth.uid()
    )
  );


-- ── 7. Messages ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content    TEXT NOT NULL CHECK (char_length(content) <= 2000),
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
      JOIN public.server_members sm ON sm.server_id = c.server_id
      WHERE c.id = messages.channel_id
        AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Messages: member insert"
  ON public.messages FOR INSERT
  WITH CHECK (
    auth.uid() = author_id
    AND EXISTS (
      SELECT 1 FROM public.channels c
      JOIN public.server_members sm ON sm.server_id = c.server_id
      WHERE c.id = messages.channel_id
        AND sm.user_id = auth.uid()
    )
  );

-- ── Enable Realtime for Live Chat & Direct Messages ─────
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;

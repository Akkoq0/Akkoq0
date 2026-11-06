// ─────────────────────────────────────────────────────────
// GhostLink — Chat Area v2 (Rich text + Interactive)
// ─────────────────────────────────────────────────────────

'use client';

import {
  memo,
  useCallback,
  useRef,
  useState,
  useEffect,
  type KeyboardEvent,
} from 'react';
import { clsx } from 'clsx';
import { useAppStore } from '@/lib/store';
import { useRealtimeChat } from '@/hooks/useRealtimeChat';
import type { Message, UserStatus } from '@/types';

// ─── Status colors ──────────────────────────────────────

const STATUS_DOT: Record<UserStatus, string> = {
  'online': 'bg-gl-online',
  'in-game': 'bg-purple-500',
  'idle': 'bg-gl-idle',
  'dnd': 'bg-gl-dnd',
  'offline': 'bg-gray-500',
};

// ─── Inline markdown-like formatting ────────────────────

function formatContent(text: string): React.ReactNode[] {
  const nodes: React.ReactNode[] = [];
  // Bold: **text**
  // Inline code: `code`
  // Simple regex-based formatting
  const parts = text.split(/(\*\*[^*]+\*\*|`[^`]+`|~~[^~]+~~)/g);

  parts.forEach((part, i) => {
    if (part.startsWith('**') && part.endsWith('**')) {
      nodes.push(<strong key={i} className="font-bold">{part.slice(2, -2)}</strong>);
    } else if (part.startsWith('`') && part.endsWith('`')) {
      nodes.push(
        <code key={i} className="rounded bg-gl-bg-darkest px-1.5 py-0.5 text-xs font-mono text-gl-accent">
          {part.slice(1, -1)}
        </code>,
      );
    } else if (part.startsWith('~~') && part.endsWith('~~')) {
      nodes.push(<del key={i} className="text-gl-text-muted">{part.slice(2, -2)}</del>);
    } else {
      nodes.push(part);
    }
  });

  return nodes;
}

// ─── Message Row (memoized) ─────────────────────────────

function MessageRow({ message, isCompact }: { message: Message; isCompact: boolean }) {
  const time = new Date(message.created_at).toLocaleTimeString('tr-TR', {
    hour: '2-digit',
    minute: '2-digit',
  });

  const authorStatus = (message.author?.status ?? 'online') as UserStatus;

  if (isCompact) {
    // Compact mode: same author consecutive — no avatar, just time on hover
    return (
      <div className="group flex gap-3 px-4 py-0.5 hover:bg-gl-bg-hover/20">
        <span className="w-10 flex-shrink-0 pt-0.5 text-right text-xxs text-gl-text-muted opacity-0 group-hover:opacity-100">
          {time}
        </span>
        <p className="min-w-0 flex-1 break-words text-sm text-gl-text-primary">
          {formatContent(message.content)}
        </p>
      </div>
    );
  }

  return (
    <div className="group flex gap-3 px-4 py-1.5 hover:bg-gl-bg-hover/20">
      {/* Avatar */}
      <div className="relative mt-0.5 h-10 w-10 flex-shrink-0">
        <div className="h-10 w-10 rounded-full bg-gl-bg-mid">
          {message.author?.avatar_url && (
            <img
              src={message.author.avatar_url}
              alt=""
              className="h-full w-full rounded-full object-cover"
              loading="lazy"
            />
          )}
        </div>
        <span className={clsx(
          'absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-gl-bg-panel',
          STATUS_DOT[authorStatus],
        )} />
      </div>

      {/* Content */}
      <div className="min-w-0 flex-1">
        <div className="flex items-baseline gap-2">
          <span className="text-sm font-semibold text-gl-accent hover:underline cursor-pointer">
            {message.author?.username ?? 'Bilinmeyen'}
          </span>
          <span className="text-xxs text-gl-text-muted">{time}</span>
        </div>
        <p className="break-words text-sm leading-relaxed text-gl-text-primary">
          {formatContent(message.content)}
        </p>
      </div>
    </div>
  );
}

const MemoizedMessageRow = memo(MessageRow);

// ─── Chat Area ──────────────────────────────────────────

export function ChatArea() {
  const activeChannelId = useAppStore((s) => s.activeChannelId);
  const messages = useAppStore((s) => s.messages);
  const channels = useAppStore((s) => s.channels);
  const ecoActive = useAppStore((s) => s.ecoMode.isActive);
  const { sendMessage } = useRealtimeChat(activeChannelId);

  const [inputValue, setInputValue] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const typingTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const channelName =
    channels.find((c) => c.id === activeChannelId)?.name ?? 'genel';

  // Auto-scroll (skip in eco mode — no DOM measurements)
  useEffect(() => {
    if (ecoActive) return;
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages.length, ecoActive]);

  const handleSend = useCallback(async () => {
    if (!inputValue.trim()) return;
    await sendMessage(inputValue);
    setInputValue('');
    setIsTyping(false);
    inputRef.current?.focus();
  }, [inputValue, sendMessage]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend],
  );

  const handleInputChange = useCallback((value: string) => {
    setInputValue(value);

    // Typing indicator with debounce
    setIsTyping(true);
    if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
    typingTimeoutRef.current = setTimeout(() => setIsTyping(false), 3000);
  }, []);

  // ── Empty state ──
  if (!activeChannelId) {
    return (
      <main className="flex flex-1 flex-col items-center justify-center bg-gl-bg-panel">
        <div className="text-center">
          <div className="mb-4 text-7xl">👻</div>
          <h2 className="text-2xl font-bold text-gl-text-primary">
            GhostLink&apos;e Hoş Geldin
          </h2>
          <p className="mt-2 max-w-sm text-sm text-gl-text-secondary">
            Sol taraftan bir metin kanalı seç ve takımınla sohbete başla.
            Rakip takımla anlık scrim için ⚡ butonunu kullan.
          </p>
          <div className="mt-6 flex justify-center gap-3">
            <div className="flex items-center gap-2 rounded-full bg-gl-bg-hover px-4 py-2 text-xs text-gl-text-muted">
              <span className="h-2 w-2 rounded-full bg-gl-online" />
              P2P Ses — \$0 Maliyet
            </div>
            <div className="flex items-center gap-2 rounded-full bg-gl-bg-hover px-4 py-2 text-xs text-gl-text-muted">
              <span className="h-2 w-2 rounded-full bg-gl-accent" />
              Ultra-Hafif — 0 FPS Kaybı
            </div>
          </div>
        </div>
      </main>
    );
  }

  // ── Determine compact messages (same author within 5 min) ──
  const messageRows = messages.map((msg, idx) => {
    const prev = idx > 0 ? messages[idx - 1] : null;
    const isCompact =
      prev !== null &&
      prev.author_id === msg.author_id &&
      new Date(msg.created_at).getTime() - new Date(prev.created_at).getTime() < 5 * 60 * 1000;
    return { msg, isCompact };
  });

  return (
    <main className="flex flex-1 flex-col bg-gl-bg-panel">
      {/* ── Channel header ── */}
      <header className="flex h-12 items-center border-b border-gl-border px-4">
        <span className="mr-2 text-xl text-gl-text-muted">#</span>
        <h3 className="text-sm font-bold text-gl-text-primary">{channelName}</h3>
        <div className="mx-3 h-6 w-px bg-gl-border" />
        <span className="text-xs text-gl-text-muted">Takım sohbeti</span>
      </header>

      {/* ── Messages ── */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto py-4 scrollbar-none">
        {messages.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center px-4">
            <div className="mb-3 flex h-16 w-16 items-center justify-center rounded-full bg-gl-bg-hover text-3xl">
              #
            </div>
            <p className="text-lg font-bold text-gl-text-primary">
              #{channelName} kanalına hoş geldin!
            </p>
            <p className="mt-1 text-sm text-gl-text-muted">
              Bu kanalın başlangıcı. İlk mesajı sen yaz.
            </p>
          </div>
        ) : (
          messageRows.map(({ msg, isCompact }) => (
            <MemoizedMessageRow key={msg.id} message={msg} isCompact={isCompact} />
          ))
        )}
      </div>

      {/* ── Typing indicator ── */}
      {isTyping && (
        <div className="px-4 text-xs text-gl-text-muted">
          <span className="inline-flex gap-0.5">
            <span className="animate-bounce" style={{ animationDelay: '0ms' }}>●</span>
            <span className="animate-bounce" style={{ animationDelay: '150ms' }}>●</span>
            <span className="animate-bounce" style={{ animationDelay: '300ms' }}>●</span>
          </span>
          <span className="ml-1">yazıyor...</span>
        </div>
      )}

      {/* ── Input ── */}
      <div className="border-t border-gl-border px-4 py-3">
        <div className="flex items-center rounded-lg bg-gl-bg-hover px-4">
          {/* Attachment button */}
          <button className="mr-2 text-gl-text-muted transition-colors hover:text-gl-text-primary">
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
            </svg>
          </button>

          <input
            ref={inputRef}
            type="text"
            value={inputValue}
            onChange={(e) => handleInputChange(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={`#${channelName} kanalına mesaj gönder`}
            className="flex-1 bg-transparent py-3 text-sm text-gl-text-primary placeholder:text-gl-text-muted outline-none"
            autoComplete="off"
            spellCheck={false}
          />

          {/* Emoji placeholder */}
          <button className="ml-1 text-gl-text-muted transition-colors hover:text-gl-text-primary">
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.182 15.182a4.5 4.5 0 0 1-6.364 0M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM9.75 9.75c0 .414-.168.75-.375.75S9 10.164 9 9.75 9.168 9 9.375 9s.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Zm5.625 0c0 .414-.168.75-.375.75s-.375-.336-.375-.75.168-.75.375-.75.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Z" />
            </svg>
          </button>

          {/* Send button */}
          <button
            onClick={handleSend}
            disabled={!inputValue.trim()}
            className={clsx(
              'ml-2 rounded-md px-3 py-1.5 text-xs font-semibold text-white transition-all',
              inputValue.trim()
                ? 'bg-gl-accent hover:bg-gl-accent-hover'
                : 'bg-gl-bg-active cursor-not-allowed opacity-40',
            )}
          >
            <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
            </svg>
          </button>
        </div>
      </div>
    </main>
  );
}

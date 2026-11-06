'use client';

// ─────────────────────────────────────────────────────────
// Meva HUD — Squad Operators & 1v1 Direct Lines Modal
// ─────────────────────────────────────────────────────────

import { memo, useEffect, useRef, useState } from 'react';
import { useAppStore } from '@/lib/store';
import { OperatorAvatar } from '@/components/ui/HudPrimitives';
import { IconClose, IconUsers, IconMessage } from '@/components/ui/MevaIcons';

export const FriendsModal = memo(function FriendsModal() {
  const showFriendsModal = useAppStore((s) => s.showFriendsModal);
  const friends = useAppStore((s) => s.friends);
  const setShowFriendsModal = useAppStore((s) => s.setShowFriendsModal);
  const addFriendRequest = useAppStore((s) => s.addFriendRequest);
  const acceptFriendRequest = useAppStore((s) => s.acceptFriendRequest);
  const removeFriend = useAppStore((s) => s.removeFriend);
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);

  const [tab, setTab] = useState<'all' | 'pending' | 'add'>('all');
  const [usernameInput, setUsernameInput] = useState('');
  const [feedback, setFeedback] = useState<string | null>(null);
  const feedbackTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (feedbackTimerRef.current) clearTimeout(feedbackTimerRef.current);
    };
  }, []);

  if (!showFriendsModal) return null;

  const acceptedFriends = friends.filter((f) => f.status === 'accepted');
  const pendingFriends = friends.filter((f) => f.status === 'pending');

  const handleAddSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const clean = usernameInput
      .replace(/[\u0000-\u001F\u007F]/g, '')
      .trim()
      .slice(0, 32);
    if (clean.length < 2) return;
    addFriendRequest(clean);
    setFeedback(`"${clean}" operatörüne çağrı iletildi.`);
    setUsernameInput('');
    if (feedbackTimerRef.current) clearTimeout(feedbackTimerRef.current);
    feedbackTimerRef.current = setTimeout(() => setFeedback(null), 3000);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/80 p-0 sm:p-4 font-sans"
      onClick={() => setShowFriendsModal(false)}
    >
      <div
        className="w-full max-w-md rounded-none sm:rounded-md bg-[#080A0E] border-t sm:border border-white/[0.08] p-5 sm:p-6 shadow-2xl max-h-[88dvh] flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between border-b border-white/[0.06] pb-4 mb-4">
          <div className="flex items-center gap-3">
            <div className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.08] flex items-center justify-center text-gl-accent">
              <IconUsers size={17} />
            </div>
            <div>
              <h2 className="font-sans text-sm font-bold tracking-wide text-gl-text-bright">
                Operatör Ağı ve 1v1 Hatlar
              </h2>
              <p className="text-xs text-gl-text-muted mt-0.5">
                Doğrudan P2P İletişim Dizini
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowFriendsModal(false)}
            className="rounded-sm w-9 h-9 bg-[#0C0E12] border border-white/[0.06] flex items-center justify-center text-gl-text-normal hover:text-gl-text-bright"
            aria-label="Kapat"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* ── Tabs ── */}
        <div className="grid grid-cols-3 gap-1.5 mb-4">
          <button
            onClick={() => setTab('all')}
            className={`rounded-sm min-h-[38px] text-xs font-bold uppercase border transition-colors ${
              tab === 'all'
                ? 'bg-[#12151C] text-gl-text-bright border-gl-accent/60'
                : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
            }`}
          >
            Kadro (<span className="font-mono">{acceptedFriends.length}</span>)
          </button>
          <button
            onClick={() => setTab('pending')}
            className={`rounded-sm min-h-[38px] text-xs font-bold uppercase border transition-colors ${
              tab === 'pending'
                ? 'bg-[#12151C] text-gl-text-bright border-gl-accent/60'
                : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
            }`}
          >
            Talepler (<span className="font-mono">{pendingFriends.length}</span>)
          </button>
          <button
            onClick={() => setTab('add')}
            className={`rounded-sm min-h-[38px] text-xs font-bold uppercase border transition-colors ${
              tab === 'add'
                ? 'bg-[#12151C] text-gl-accent border-gl-accent/60'
                : 'bg-[#0C0E12] text-gl-text-muted border-white/[0.05]'
            }`}
          >
            + Operatör Ekle
          </button>
        </div>

        {/* ── Content ── */}
        <div className="flex-1 overflow-y-auto space-y-2">
          {tab === 'all' &&
            acceptedFriends.map((f) => {
              const friend = f.friend;
              if (!friend) return null;
              return (
                <div
                  key={f.id}
                  className="rounded-sm flex items-center justify-between p-3 bg-[#0C0E12] border border-white/[0.06]"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <OperatorAvatar
                      name={friend.username}
                      status={friend.status}
                      size="md"
                    />
                    <div className="min-w-0">
                      <p className="text-sm font-bold text-gl-text-bright truncate">
                        {friend.username}
                      </p>
                      <p className="text-xs text-gl-text-muted truncate">
                        {friend.activity ?? 'Hazır Kıta'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <button
                      onClick={() => {
                        setActiveDMUser(friend.id);
                        setShowFriendsModal(false);
                      }}
                      className="rounded-sm min-h-[36px] px-3 bg-[#12151C] hover:bg-gl-accent text-gl-text-bright hover:text-white border border-white/[0.08] text-xs font-bold flex items-center gap-1.5 transition-colors"
                    >
                      <IconMessage size={13} />
                      <span>1v1</span>
                    </button>
                    <button
                      onClick={() => removeFriend(friend.id)}
                      className="rounded-sm w-9 h-9 bg-[#050608] hover:bg-gl-danger/15 text-gl-text-muted hover:text-gl-danger border border-white/[0.06] flex items-center justify-center transition-colors"
                      title="Kaldır"
                      aria-label="Operatörü kaldır"
                    >
                      <IconClose size={14} />
                    </button>
                  </div>
                </div>
              );
            })}

          {tab === 'pending' &&
            (pendingFriends.length === 0 ? (
              <p className="text-xs text-gl-text-muted text-center py-8">
                Bekleyen bağlantı talebi bulunmuyor.
              </p>
            ) : (
              pendingFriends.map((f) => {
                const friend = f.friend;
                if (!friend) return null;
                return (
                  <div
                    key={f.id}
                    className="rounded-sm flex items-center justify-between p-3 bg-[#0C0E12] border border-white/[0.06]"
                  >
                    <div className="flex items-center gap-3">
                      <OperatorAvatar name={friend.username} size="md" />
                      <div>
                        <p className="text-sm font-bold text-gl-text-bright">
                          {friend.username}
                        </p>
                        <p className="text-[11px] font-semibold text-[#F59E0B]">
                          Gelen Bağlantı Çağrısı
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => acceptFriendRequest(f.id)}
                        className="rounded-sm min-h-[36px] px-3 bg-gl-accent text-white text-xs font-bold"
                      >
                        Onayla
                      </button>
                      <button
                        onClick={() => removeFriend(friend.id)}
                        className="rounded-sm w-9 h-9 bg-[#050608] text-gl-danger border border-white/[0.06] flex items-center justify-center"
                        aria-label="Reddet"
                      >
                        <IconClose size={14} />
                      </button>
                    </div>
                  </div>
                );
              })
            ))}

          {tab === 'add' && (
            <form onSubmit={handleAddSubmit} className="space-y-3 pt-1">
              <label className="block text-xs font-semibold text-gl-text-normal">
                Operatör Çağrı Kodu / Kullanıcı Adı
              </label>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={usernameInput}
                  onChange={(e) => setUsernameInput(e.target.value)}
                  placeholder="Örn: woxic, Majer..."
                  maxLength={32}
                  className="rounded-sm flex-1 h-11 bg-[#050608] text-xs text-gl-text-bright px-3.5 border border-white/[0.08] focus:outline-none focus:border-gl-accent"
                />
                <button
                  type="submit"
                  disabled={usernameInput.trim().length < 2}
                  className="rounded-sm min-h-[44px] px-4 bg-gl-accent hover:bg-gl-accent-hover disabled:opacity-40 text-white text-xs font-bold tracking-wide"
                >
                  Ekle
                </button>
              </div>
              {feedback && (
                <p className="rounded-sm text-xs font-medium text-[#F59E0B] bg-[#0C0E12] border border-[#F59E0B]/40 px-3 py-2">
                  {feedback}
                </p>
              )}
            </form>
          )}
        </div>
      </div>
    </div>
  );
});

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
    setFeedback(`"${clean}" operatörüne bağlantı çağrısı iletildi.`);
    setUsernameInput('');
    if (feedbackTimerRef.current) clearTimeout(feedbackTimerRef.current);
    feedbackTimerRef.current = setTimeout(() => setFeedback(null), 3000);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center exec-backdrop p-0 sm:p-4 font-sans tabular-nums"
      onClick={() => setShowFriendsModal(false)}
    >
      <div
        className="w-full max-w-md rounded-t-2xl sm:rounded-2xl exec-modal p-5 sm:p-6 max-h-[88dvh] flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between border-b border-[#881A26]/20 pb-4 mb-4">
          <div className="flex items-center gap-3">
            <div className="rounded-xl w-10 h-10 bg-gradient-to-br from-[#591019]/50 to-[#0C0809] border border-[#881A26]/40 flex items-center justify-center text-[#E35D6A]">
              <IconUsers size={18} />
            </div>
            <div>
              <h2 className="text-sm font-bold tracking-tight text-[#F4EFF0]">
                Operatör Ağı ve 1v1 Hatlar
              </h2>
              <p className="text-xs text-[#8E7F83] mt-0.5">
                Doğrudan P2P İletişim Dizini
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setShowFriendsModal(false)}
            className="rounded-xl w-9 h-9 bg-[#120A0D] hover:bg-[#1B0D12] border border-[#881A26]/25 flex items-center justify-center text-[#9E8F93] hover:text-[#F4EFF0] transition-colors"
            aria-label="Kapat"
          >
            <IconClose size={16} />
          </button>
        </div>

        {/* ── Tabs ── */}
        <div className="grid grid-cols-3 gap-1 p-1 rounded-xl bg-[#0A0708] border border-[#881A26]/20 mb-4">
          <button
            type="button"
            onClick={() => setTab('all')}
            className={`rounded-lg min-h-[36px] text-xs font-bold transition-all ${
              tab === 'all'
                ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
            }`}
          >
            Kadro · {acceptedFriends.length}
          </button>
          <button
            type="button"
            onClick={() => setTab('pending')}
            className={`rounded-lg min-h-[36px] text-xs font-bold transition-all ${
              tab === 'pending'
                ? 'bg-gradient-to-b from-[#2A0E15] to-[#13090C] text-[#F4EFF0] border border-[#881A26]/40'
                : 'text-[#8E7F83] hover:text-[#F4EFF0] border border-transparent'
            }`}
          >
            Talepler · {pendingFriends.length}
          </button>
          <button
            type="button"
            onClick={() => setTab('add')}
            className={`rounded-lg min-h-[36px] text-xs font-bold transition-all ${
              tab === 'add'
                ? 'bg-[#7A121D]/35 text-[#F08C96] border border-[#A61B29]/55'
                : 'text-[#D95360] hover:text-[#F08C96] border border-transparent'
            }`}
          >
            + Operatör
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
                  className="rounded-xl flex items-center justify-between p-3 bg-[#11090C]/90 border border-[#881A26]/20 hover:border-[#A61B29]/40 transition-colors"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <OperatorAvatar
                      name={friend.username}
                      status={friend.status}
                      size="md"
                    />
                    <div className="min-w-0">
                      <p className="text-sm font-bold text-[#F4EFF0] truncate">
                        {friend.username}
                      </p>
                      <p className="text-xs text-[#8E7F83] truncate">
                        {friend.activity ?? 'Hazır Kıta'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <button
                      type="button"
                      onClick={() => {
                        setActiveDMUser(friend.id);
                        setShowFriendsModal(false);
                      }}
                      className="rounded-xl min-h-[36px] px-3 bg-[#0C0809] hover:bg-[#7A121D]/45 text-[#F4EFF0] border border-[#881A26]/30 hover:border-[#B51D2C]/60 text-xs font-bold flex items-center gap-1.5 transition-colors"
                    >
                      <IconMessage size={13} />
                      <span>1v1</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => removeFriend(friend.id)}
                      className="rounded-xl w-9 h-9 bg-[#0C0809] hover:bg-[#7A121D]/25 text-[#8E7F83] hover:text-[#F08C96] border border-[#881A26]/20 flex items-center justify-center transition-colors"
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
              <p className="text-xs text-[#8E7F83] text-center py-8">
                Bekleyen bağlantı talebi bulunmuyor.
              </p>
            ) : (
              pendingFriends.map((f) => {
                const friend = f.friend;
                if (!friend) return null;
                return (
                  <div
                    key={f.id}
                    className="rounded-xl flex items-center justify-between p-3 bg-[#11090C]/90 border border-[#881A26]/25"
                  >
                    <div className="flex items-center gap-3">
                      <OperatorAvatar name={friend.username} size="md" />
                      <div>
                        <p className="text-sm font-bold text-[#F4EFF0]">
                          {friend.username}
                        </p>
                        <p className="text-[11px] font-semibold text-[#E35D6A]">
                          Gelen Bağlantı Çağrısı
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
                        type="button"
                        onClick={() => acceptFriendRequest(f.id)}
                        className="rounded-xl min-h-[36px] px-3 crimson-cta text-xs font-bold"
                      >
                        Onayla
                      </button>
                      <button
                        type="button"
                        onClick={() => removeFriend(friend.id)}
                        className="rounded-xl w-9 h-9 bg-[#0C0809] text-[#F08C96] border border-[#881A26]/25 flex items-center justify-center"
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
              <label className="block text-xs font-semibold text-[#C4B6BA]">
                Operatör Çağrı Kodu / Kullanıcı Adı
              </label>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={usernameInput}
                  onChange={(e) => setUsernameInput(e.target.value)}
                  placeholder="Örn: woxic, Majer..."
                  maxLength={32}
                  className="rounded-xl flex-1 h-11 bg-[#0A0708] text-xs text-[#F4EFF0] placeholder:text-[#786A6E] px-3.5 border border-[#881A26]/25 focus:outline-none focus:border-[#B51D2C]/65 transition-colors"
                />
                <button
                  type="submit"
                  disabled={usernameInput.trim().length < 2}
                  className="rounded-xl min-h-[44px] px-4 crimson-cta disabled:opacity-40 text-xs font-bold tracking-wide transition-all"
                >
                  Çağrı Gönder
                </button>
              </div>
              {feedback && (
                <p className="rounded-xl text-xs font-medium text-[#ED8793] bg-[#160A0E] border border-[#881A26]/40 px-3.5 py-2.5">
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

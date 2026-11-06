// ─────────────────────────────────────────────────────────
// GhostLink — Friends & 1v1 DM Modal (components/friends/FriendsModal.tsx)
// ─────────────────────────────────────────────────────────

'use client';

import { useState } from 'react';
import { useAppStore } from '@/lib/store';
import { useHUDStore } from '@/store/useHUDStore';
import { clsx } from 'clsx';
import type { Friendship } from '@/types';

type FriendsTab = 'online' | 'all' | 'pending' | 'add';

export function FriendsModal() {
  const show = useAppStore((s) => s.showFriendsModal);
  const setShow = useAppStore((s) => s.setShowFriendsModal);
  const friends = useAppStore((s) => s.friends);
  const addFriendRequest = useAppStore((s) => s.addFriendRequest);
  const acceptFriendRequest = useAppStore((s) => s.acceptFriendRequest);
  const removeFriend = useAppStore((s) => s.removeFriend);
  const setActiveDMUser = useAppStore((s) => s.setActiveDMUser);
  const setActiveVoiceChannel = useAppStore((s) => s.setActiveVoiceChannel);
  const openHUD = useHUDStore((s) => s.openHUD);

  const [activeTab, setActiveTab] = useState<FriendsTab>('online');
  const [inputUsername, setInputUsername] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  if (!show) return null;

  const acceptedFriends = friends.filter((f) => f.status === 'accepted');
  const pendingFriends = friends.filter((f) => f.status === 'pending');
  const onlineFriends = acceptedFriends.filter(
    (f) => f.friend?.status === 'online' || f.friend?.status === 'in-game'
  );

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputUsername.trim()) return;
    addFriendRequest(inputUsername.trim());
    setSuccessMessage(`"${inputUsername.trim()}" kullanıcısına arkadaşlık isteği gönderildi!`);
    setInputUsername('');
    setTimeout(() => setSuccessMessage(''), 3000);
  };

  const handleStartDM = (friendship: Friendship) => {
    if (friendship.friend) {
      setActiveDMUser(friendship.friend.id);
      setShow(false);
    }
  };

  const handleCallP2P = (friendship: Friendship) => {
    if (friendship.friend) {
      // 1v1 direct P2P room
      setActiveVoiceChannel(`dm_${friendship.friend.id}`);
      setShow(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4 animate-in fade-in duration-150">
      <div className="w-full max-w-2xl rounded-2xl border border-gl-border bg-gl-bg-panel p-6 shadow-2xl relative overflow-hidden ghost-glass">
        {/* Subtle Cyberpunk Accent Light Bar */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-gl-accent to-transparent" />

        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-gl-border">
          <div className="flex items-center gap-3">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-gl-accent/15 text-gl-accent text-lg font-bold border border-gl-accent/30 shadow-[0_0_12px_rgba(0,242,254,0.3)]">
              👥
            </span>
            <div>
              <h3 className="text-base font-bold text-gl-text-primary tracking-wide">
                ARKADAŞLAR & 1v1 DOKÜMAN
              </h3>
              <p className="text-xxs text-gl-text-muted">
                Birebir Şifreli P2P İletişim ve Takım Listesi
              </p>
            </div>
          </div>
          <button
            onClick={() => setShow(false)}
            className="text-gl-text-muted hover:text-gl-text-primary text-xl p-1 transition-colors"
          >
            ✕
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex items-center gap-2 mt-4 pb-3 border-b border-white/5 overflow-x-auto scrollbar-none">
          <button
            onClick={() => setActiveTab('online')}
            className={clsx(
              'px-3.5 py-1.5 rounded-xl text-xs font-mono font-bold transition-all',
              activeTab === 'online'
                ? 'bg-gl-accent/20 border border-gl-accent/50 text-gl-accent shadow-[0_0_10px_rgba(0,242,254,0.2)]'
                : 'text-gl-text-secondary hover:text-white'
            )}
          >
            Çevrimiçi ({onlineFriends.length})
          </button>

          <button
            onClick={() => setActiveTab('all')}
            className={clsx(
              'px-3.5 py-1.5 rounded-xl text-xs font-mono font-bold transition-all',
              activeTab === 'all'
                ? 'bg-gl-accent/20 border border-gl-accent/50 text-gl-accent shadow-[0_0_10px_rgba(0,242,254,0.2)]'
                : 'text-gl-text-secondary hover:text-white'
            )}
          >
            Tümü ({acceptedFriends.length})
          </button>

          <button
            onClick={() => setActiveTab('pending')}
            className={clsx(
              'px-3.5 py-1.5 rounded-xl text-xs font-mono font-bold transition-all relative',
              activeTab === 'pending'
                ? 'bg-gl-accent/20 border border-gl-accent/50 text-gl-accent shadow-[0_0_10px_rgba(0,242,254,0.2)]'
                : 'text-gl-text-secondary hover:text-white'
            )}
          >
            Bekleyen ({pendingFriends.length})
            {pendingFriends.length > 0 && (
              <span className="ml-1.5 h-2 w-2 rounded-full bg-gl-accent inline-block animate-ping" />
            )}
          </button>

          <button
            onClick={() => setActiveTab('add')}
            className={clsx(
              'px-3.5 py-1.5 rounded-xl text-xs font-mono font-bold transition-all ml-auto',
              activeTab === 'add'
                ? 'bg-emerald-500/20 border border-emerald-500/50 text-emerald-400 shadow-[0_0_10px_rgba(16,185,129,0.2)]'
                : 'bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20'
            )}
          >
            + Arkadaş Ekle
          </button>
        </div>

        {/* Tab Content */}
        <div className="mt-4 max-h-[55vh] min-h-[220px] overflow-y-auto pr-1 scrollbar-none">
          {activeTab === 'add' ? (
            <div className="p-4 space-y-4">
              <form onSubmit={handleAdd} className="space-y-3">
                <label className="block text-xs font-bold text-gl-text-secondary uppercase tracking-wider font-mono">
                  OYUNCU ADI VEYA ETİKETİ GİRİN
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={inputUsername}
                    onChange={(e) => setInputUsername(e.target.value)}
                    placeholder="Örn: XANTARES#1337 veya cNed"
                    className="flex-1 rounded-xl bg-gl-bg-darkest px-4 py-2.5 text-xs font-mono text-gl-text-primary placeholder:text-gl-text-muted outline-none border border-white/10 focus:border-gl-accent transition-colors"
                    autoFocus
                  />
                  <button
                    type="submit"
                    className="ghost-btn-interactive px-5 py-2.5 rounded-xl bg-gl-accent text-black font-mono font-bold text-xs shadow-[0_0_12px_rgba(0,242,254,0.3)]"
                  >
                    İSTEK GÖNDER
                  </button>
                </div>
              </form>

              {successMessage && (
                <div className="p-3 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-xs font-mono">
                  ✓ {successMessage}
                </div>
              )}

              <div className="rounded-xl bg-gl-bg-darkest/70 p-3.5 border border-white/5 text-xxs font-mono text-gl-text-muted space-y-1">
                <p>💡 Arkadaş eklediğinizde sunuculardan bağımsız 1v1 mesajlaşabilir ve tek tıkla doğrudan P2P sesli arama başlatabilirsiniz.</p>
              </div>
            </div>
          ) : activeTab === 'pending' ? (
            <div className="space-y-2">
              {pendingFriends.length === 0 ? (
                <div className="text-center py-12 text-gl-text-muted font-mono text-xs">
                  Bekleyen arkadaşlık isteği bulunmuyor.
                </div>
              ) : (
                pendingFriends.map((f) => (
                  <div
                    key={f.id}
                    className="p-3 rounded-xl bg-gl-bg-darkest/70 border border-white/5 flex items-center justify-between"
                  >
                    <div className="flex items-center gap-2.5">
                      <div className="h-9 w-9 rounded-xl bg-gl-accent/15 border border-gl-accent/30 flex items-center justify-center font-bold text-gl-accent text-xs">
                        {f.friend?.username[0]?.toUpperCase() ?? 'G'}
                      </div>
                      <div>
                        <span className="text-xs font-bold text-gl-text-primary block">
                          {f.friend?.username}
                        </span>
                        <span className="text-[10px] font-mono text-amber-400">
                          Gelen İstek
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => acceptFriendRequest(f.id)}
                        className="px-3 py-1.5 rounded-lg bg-emerald-500/20 hover:bg-emerald-500/30 border border-emerald-500/40 text-emerald-400 text-xs font-mono font-bold transition-all"
                      >
                        ✓ Kabul Et
                      </button>
                      <button
                        onClick={() => removeFriend(f.friend_id)}
                        className="px-3 py-1.5 rounded-lg bg-rose-500/20 hover:bg-rose-500/30 border border-rose-500/40 text-rose-400 text-xs font-mono font-bold transition-all"
                      >
                        ✕ Reddet
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          ) : (
            <div className="space-y-1.5">
              {(activeTab === 'online' ? onlineFriends : acceptedFriends).length === 0 ? (
                <div className="text-center py-12 text-gl-text-muted font-mono text-xs">
                  {activeTab === 'online' ? 'Şu anda çevrimiçi arkadaş yok.' : 'Henüz arkadaş eklenmemiş.'}
                </div>
              ) : (
                (activeTab === 'online' ? onlineFriends : acceptedFriends).map((f) => (
                  <div
                    key={f.id}
                    className="p-3 rounded-xl bg-gl-bg-darkest/60 border border-white/5 hover:border-gl-accent/30 flex items-center justify-between transition-colors group"
                  >
                    <div
                      onClick={() => f.friend && openHUD(f.friend)}
                      className="flex items-center gap-2.5 cursor-pointer min-w-0"
                    >
                      <div className="relative h-9 w-9 rounded-xl bg-gl-bg-panel border border-white/10 flex items-center justify-center font-bold text-xs text-gl-text-primary flex-shrink-0">
                        {f.friend?.username[0]?.toUpperCase() ?? 'G'}
                        <span
                          className={clsx(
                            'absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border border-gl-bg-darkest',
                            f.friend?.status === 'in-game' ? 'bg-purple-400' : 'bg-emerald-400'
                          )}
                        />
                      </div>
                      <div className="min-w-0">
                        <span className="text-xs font-bold text-gl-text-primary block truncate group-hover:text-gl-accent transition-colors">
                          {f.friend?.username}
                        </span>
                        <span className="text-[10px] font-mono text-gl-text-muted block truncate">
                          {f.friend?.activity ?? (f.friend?.status === 'in-game' ? 'Oyunda' : 'Çevrimiçi')}
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5">
                      {/* DM Button */}
                      <button
                        onClick={() => handleStartDM(f)}
                        className="ghost-btn-interactive p-2 rounded-lg bg-white/5 hover:bg-gl-accent/20 border border-white/10 hover:border-gl-accent/40 text-gl-text-secondary hover:text-gl-accent transition-all text-xs"
                        title="Birebir Özel Mesajlaş"
                      >
                        💬 DM
                      </button>

                      {/* 1v1 P2P Voice Call */}
                      <button
                        onClick={() => handleCallP2P(f)}
                        className="ghost-btn-interactive p-2 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 transition-all text-xs"
                        title="1v1 P2P Sesli Ara"
                      >
                        📞 P2P Ses
                      </button>

                      {/* Remove Friend */}
                      <button
                        onClick={() => removeFriend(f.friend_id)}
                        className="p-2 rounded-lg text-gl-text-muted hover:text-rose-400 hover:bg-rose-500/10 transition-colors text-xs"
                        title="Arkadaşlıktan Çıkar"
                      >
                        ✕
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="mt-4 pt-3 border-t border-gl-border flex justify-between items-center text-xxs font-mono text-gl-text-muted">
          <span>P2P MESH // %0 VERİTABANI YÜKÜ</span>
          <button
            onClick={() => setShow(false)}
            className="rounded-xl bg-gl-bg-hover hover:bg-gl-bg-active px-4 py-2 text-xs font-bold text-gl-text-primary transition-all"
          >
            Kapat
          </button>
        </div>
      </div>
    </div>
  );
}


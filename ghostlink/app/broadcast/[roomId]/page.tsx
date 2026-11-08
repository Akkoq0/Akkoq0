import React, { Suspense } from 'react';
import BroadcastClient from './BroadcastClient';

export function generateStaticParams() {
  return [{ roomId: 'demo' }, { roomId: 'arena-alpha' }];
}

export default function BroadcastPage() {
  return (
    <Suspense fallback={<div className="bg-transparent" />}>
      <BroadcastClient />
    </Suspense>
  );
}

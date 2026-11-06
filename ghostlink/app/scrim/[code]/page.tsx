import ScrimRoomClient from './ScrimRoomClient';

export function generateStaticParams() {
  return [{ code: 'demo' }];
}

export default function ScrimRoomPage() {
  return <ScrimRoomClient />;
}

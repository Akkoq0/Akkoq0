import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'gg.ghostlink.app',
  appName: 'Meva HUD',
  webDir: 'out',
  server: {
    androidScheme: 'https',
  },
  android: {
    allowMixedContent: false,
  },
};

export default config;

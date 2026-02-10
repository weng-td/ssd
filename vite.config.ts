import { execSync } from "node:child_process";

import { defineConfig } from "vite";
import { sveltekit } from "@sveltejs/kit/vite";

const commitHash = "dev";

// Allow configuring remote server via environment variable
// Usage: VITE_SERVER_URL=http://192.168.1.100:8051 npm run dev
const serverUrl = process.env.VITE_SERVER_URL || "http://127.0.0.1:8051";

export default defineConfig({
  define: {
    __APP_VERSION__: JSON.stringify("0.4.1-" + commitHash),
  },

  plugins: [sveltekit()],

  build: {
    // Optimize chunk size
    chunkSizeWarningLimit: 1000,

    // Enable minification


    // Code splitting for better caching


    // Enable source maps only in dev
    sourcemap: false,

    // CSS code splitting
    cssCodeSplit: true,

    // Optimize asset handling
    assetsInlineLimit: 4096, // Inline assets < 4kb
  },

  server: {
    host: true, // Allow access from network
    proxy: {
      "/api": {
        target: serverUrl,
        changeOrigin: true,
        ws: true, // Enable WebSocket proxy
        secure: false, // Allow self-signed certificates
      },
    },
  },

  // Optimize dependencies
  optimizeDeps: {
    include: ['svelte'],
    exclude: [],
  },
});

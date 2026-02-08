import { execSync } from "node:child_process";
import { defineConfig } from "vite";
import { sveltekit } from "@sveltejs/kit/vite";

// Nếu sau này muốn lấy commit thật thì mở lại
// const commitHash = execSync("git rev-parse --short HEAD").toString().trim();
const commitHash = "dev";

export default defineConfig({
  define: {
    __APP_VERSION__: JSON.stringify("0.4.1-" + commitHash),
  },

  plugins: [sveltekit()],

  server: {
    // 🔥 BẮT BUỘC cho cloudflared
    host: true,

    // 🔥 Cho phép domain Quick Tunnel
    allowedHosts: [
      ".trycloudflare.com",
    ],

    // 🔥 Fix màn hình trắng do HMR qua HTTPS tunnel
    hmr: {
      protocol: "wss",
      clientPort: 443,
    },

    // Backend API (sshx-server)
    proxy: {
      "/api": {
        target: "http://127.0.0.1:8051",
        changeOrigin: true,
        ws: true,
      },
    },
  },
});

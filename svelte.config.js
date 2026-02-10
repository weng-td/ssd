import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter({
      pages: 'dist',
      assets: 'dist',
      fallback: 'index.html',
      precompress: true,
      strict: false
    }),

    // Optimize build output
    inlineStyleThreshold: 1024,

    // Prerender settings
    prerender: {
      handleHttpError: 'warn',
      handleMissingId: 'warn'
    },

    // CSP configuration - Relaxed for WebAssembly
    // CSP configuration - Relaxed for WebAssembly
    /* csp: {
      mode: 'auto',
      directives: {
        'script-src': ['self', 'unsafe-inline', 'unsafe-eval', 'blob:'],
        'object-src': ['none'],
        'base-uri': ['self']
      }
    } */
  }
};

export default config;

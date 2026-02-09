import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter({
      pages: 'build',
      assets: 'build',
      fallback: 'index.html',
      precompress: true, // Enable gzip/brotli compression
      strict: true
    }),

    // Optimize build output
    inlineStyleThreshold: 1024, // Inline small CSS

    // Prerender for faster initial load
    prerender: {
      handleHttpError: 'warn',
      handleMissingId: 'warn'
    },

    // CSP for security and performance
    csp: {
      mode: 'auto',
      directives: {
        'script-src': ['self']
      }
    }
  }
};

export default config;

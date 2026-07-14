import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://realgoldfang.github.io',
  output: 'static',
  build: {
    outDir: '../dist'
  }
});

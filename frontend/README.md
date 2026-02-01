# Frontend

This directory is set up for a Node.js/npm-based frontend (React, Vue, Svelte, etc.).

## Quick Start

```bash
# Create a new Vite + React app
npm create vite@latest . -- --template react-ts

# Or Vue
npm create vite@latest . -- --template vue-ts

# Or Svelte
npm create vite@latest . -- --template svelte-ts
```

## Makefile

The Makefile wraps npm commands for consistency:

- `make install` - npm install
- `make dev` - npm run dev
- `make lint` - npm run lint
- `make build` - npm run build
- `make clean` - Remove dist/

## package.json Scripts

Ensure your package.json has these scripts:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "lint": "eslint src"
  }
}
```

# Querial

**Design SQL once. Run it on every database.**

This repository is the public marketing and documentation site for Querial, a self-hosted SQL-native control plane.

## Pages

- **Home** — Product overview, how it works, features, personas, architecture, screenshots (placeholders), roadmap, FAQ
- **About** — Why Querial exists
- **Docs** — Guides by persona
  - Developers — Workspace, DAG designer, SQL workspace, packages
  - DevOps — Connections, deployments, scheduling, agents/keys/Git, artifacts, retry
  - Project / Team / Platform admins
  - Privacy Policy and Terms of Use
- **Contact** — Docs and Platform admin path (no outbound code-host links)

## Tech stack

- Astro
- React
- Tailwind CSS
- Framer Motion
- Radix UI
- Lucide Icons

Screenshot images under `public/screenshots/desktop/` are placeholders and should be replaced with captures from Workspace.

## Development

```bash
npm install
npm run dev
```

Site: `http://localhost:4321`.

```bash
npm run build
npm run preview
```

## Deployment

The included workflow builds the static site on push to `main` and publishes the `dist` folder.

## License

The original site template is MIT licensed — see [LICENSE](LICENSE). Querial product, content, and branding are not covered by that template license.

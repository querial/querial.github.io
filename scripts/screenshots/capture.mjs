import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const siteRoot = path.resolve(__dirname, "../..");
const webRoot = path.resolve(
  siteRoot,
  "../trex-querial/src/Trex.Querial.Web/wwwroot",
);
const outDir = path.join(siteRoot, "public/screenshots/desktop");

const MIME = {
  ".css": "text/css",
  ".js": "text/javascript",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".woff2": "font/woff2",
  ".woff": "font/woff",
  ".ttf": "font/ttf",
  ".map": "application/json",
  ".html": "text/html; charset=utf-8",
};

function chrome(active, inner, extraCss = "") {
  const item = (id, icon, label) =>
    `<li class="nav-item"><a href="#" class="nav-link${active === id ? " active" : ""}"><span class="nav-link-icon"><i data-lucide="${icon}"></i></span><span class="nav-link-title">${label}</span></a></li>`;

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="stylesheet" href="/lib/tabler/css/tabler.min.css" />
  <link rel="stylesheet" href="/css/site.css" />
  ${extraCss}
  <style>
    html, body { height: 100%; overflow: hidden; }
    .shot-hide-scroll { overflow: hidden !important; }
    .dag-canvas {
      flex: 1; min-height: 420px;
      background: radial-gradient(circle, #d0d5dd 1px, transparent 1px) 0 0 / 18px 18px;
      background-color: #f4f6f9;
      position: relative;
    }
    [data-bs-theme="dark"] .dag-canvas {
      background: radial-gradient(circle, #3f3f46 1px, transparent 1px) 0 0 / 18px 18px;
      background-color: #18181b;
    }
    .dag-node {
      position: absolute; width: 200px; padding: 0.75rem 0.9rem;
      background: var(--tblr-bg-surface, #fff);
      border: 1px solid var(--tblr-border-color);
      border-radius: 0.5rem; box-shadow: 0 4px 12px rgba(24,36,51,.08);
    }
    .sql-fake {
      font-family: ui-monospace, Consolas, monospace; font-size: 13px; line-height: 1.55;
      background: #1e1e1e; color: #d4d4d4; border-radius: 0 0 0.5rem 0.5rem;
      padding: 1rem 1.25rem; min-height: 420px; white-space: pre;
    }
    .sql-kw { color: #569cd6; } .sql-fn { color: #dcdcaa; } .sql-str { color: #ce9178; }
    .sql-cm { color: #6a9955; }
  </style>
</head>
<body data-bs-theme="light" class="content-full-width shot-hide-scroll">
  <div class="page">
    <aside id="main-sidebar" class="navbar navbar-vertical navbar-expand-lg d-flex flex-column">
      <div class="container-fluid flex-column h-100 p-0">
        <div class="sidebar-header d-flex align-items-center justify-content-between w-100 px-3">
          <h1 class="navbar-brand m-0 p-0">
            <a href="#" class="brand-link d-flex align-items-center">
              <img src="/img/logo/querial_light.svg" alt="Querial" height="26" class="navbar-brand-image querial-only-light" />
              <img src="/img/logo/querial_dark.svg" alt="Querial" height="26" class="navbar-brand-image querial-only-dark" />
            </a>
          </h1>
          <button type="button" class="sidebar-toggle-btn btn btn-icon p-1">
            <span class="icon-expanded-close"><i data-lucide="panel-left-close"></i></span>
          </button>
        </div>
        <nav id="sidebar-menu" class="navbar-collapse w-100 flex-column align-items-stretch">
          <ul class="navbar-nav w-100 px-2">
            ${item("home", "layout-dashboard", "Dashboard")}
            <li class="nav-item sidebar-nav-group" data-nav-group="design">
              <button type="button" class="sidebar-nav-group-toggle" aria-expanded="true">
                <span class="nav-link-icon"><i data-lucide="pen-tool"></i></span>
                <span class="nav-link-title">Design</span>
                <span class="sidebar-nav-group-chevron"><i data-lucide="chevron-down"></i></span>
              </button>
              <ul class="sidebar-nav-group-items">
                ${item("connections", "database", "Connections")}
                ${item("pipelines", "workflow", "Pipelines")}
                ${item("members", "users-round", "Members")}
                ${item("git", "git-branch", "Git repositories")}
              </ul>
            </li>
            <li class="nav-item sidebar-nav-group" data-nav-group="operations">
              <button type="button" class="sidebar-nav-group-toggle" aria-expanded="true">
                <span class="nav-link-icon"><i data-lucide="gauge"></i></span>
                <span class="nav-link-title">Operations</span>
                <span class="sidebar-nav-group-chevron"><i data-lucide="chevron-down"></i></span>
              </button>
              <ul class="sidebar-nav-group-items">
                ${item("deployments", "rocket", "Deployments")}
                ${item("schedules", "calendar-clock", "Schedules")}
                ${item("runs", "activity", "Run history")}
              </ul>
            </li>
            <li class="nav-item sidebar-nav-group" data-nav-group="data">
              <button type="button" class="sidebar-nav-group-toggle" aria-expanded="true">
                <span class="nav-link-icon"><i data-lucide="wrench"></i></span>
                <span class="nav-link-title">Data tools</span>
                <span class="sidebar-nav-group-chevron"><i data-lucide="chevron-down"></i></span>
              </button>
              <ul class="sidebar-nav-group-items">
                ${item("sql", "code-2", "SQL Editor")}
                ${item("schema", "list-tree", "Schema browser")}
                ${item("assist", "bot", "SQL Assist")}
              </ul>
            </li>
            <li class="nav-item sidebar-nav-group" data-nav-group="workers">
              <button type="button" class="sidebar-nav-group-toggle" aria-expanded="false">
                <span class="nav-link-icon"><i data-lucide="server"></i></span>
                <span class="nav-link-title">Workers</span>
                <span class="sidebar-nav-group-chevron"><i data-lucide="chevron-down"></i></span>
              </button>
              <ul class="sidebar-nav-group-items" style="display:none">
                ${item("agents", "cpu", "Agents")}
                ${item("pools", "layers", "Agent pools")}
              </ul>
            </li>
          </ul>
        </nav>
        <div class="sidebar-footer border-top w-100 p-2 mt-auto">
          <button type="button" class="sidebar-footer-item">
            <span class="sidebar-footer-icon text-primary"><i data-lucide="building-2"></i></span>
            <span class="sidebar-footer-text">Northwind / Analytics</span>
          </button>
          <button type="button" class="sidebar-footer-item">
            <span class="sidebar-footer-icon text-secondary"><i data-lucide="user"></i></span>
            <span class="sidebar-footer-text">Alex Chen</span>
          </button>
        </div>
      </div>
    </aside>
    <div class="page-wrapper">${inner}</div>
  </div>
  <script src="/lib/lucide/lucide.min.js"></script>
  <script>lucide.createIcons();</script>
</body>
</html>`;
}

const pages = {
  connections: chrome(
    "connections",
    `<div class="page-header d-print-none"><div class="container-xl"><div class="row g-2 align-items-center">
      <div class="col"><h2 class="page-title">Connections</h2></div>
      <div class="col-auto ms-auto"><a class="btn btn-primary"><i data-lucide="plus" class="me-2"></i>Create connection</a></div>
    </div></div></div>
    <div class="page-body"><div class="container-xl"><div class="card">
      <div class="card-header"><form class="querial-list-filters">
        <div class="querial-list-filters-search"><i data-lucide="search"></i>
          <input class="querial-list-filters-input" placeholder="Search by name or code…" /></div>
        <div class="querial-list-filters-controls">
          <div class="querial-list-filters-field"><label>Provider</label>
            <select class="form-select querial-list-filters-select"><option>All providers</option></select></div>
          <label class="form-check form-switch querial-list-filters-switch mb-0">
            <input type="checkbox" class="form-check-input" checked />
            <span class="form-check-label">Show disabled</span>
          </label>
        </div>
      </form></div>
      <div class="card-body p-0"><table class="table table-vcenter card-table">
        <thead><tr><th>Connection name</th><th>Provider</th><th>Endpoints</th><th>Status</th><th class="w-1">Actions</th></tr></thead>
        <tbody>
          <tr><td><div class="d-flex align-items-center gap-2"><span class="avatar avatar-sm rounded bg-blue-lt text-blue"><i data-lucide="database"></i></span>
            <div><a class="text-reset d-block">pg_analytics</a><div class="text-secondary small">PostgreSQL warehouse</div></div></div></td>
            <td><span class="badge bg-blue-lt">PostgreSQL</span></td>
            <td><div class="d-flex flex-wrap gap-1"><span class="badge bg-green-lt">Dev</span><span class="badge bg-azure-lt">Stg</span><span class="badge bg-purple-lt">Prd</span></div></td>
            <td><span class="badge bg-green">Active</span></td>
            <td class="text-nowrap"><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="pencil"></i></a></td></tr>
          <tr><td><div class="d-flex align-items-center gap-2"><span class="avatar avatar-sm rounded bg-azure-lt text-azure"><i data-lucide="database"></i></span>
            <div><a class="text-reset d-block">mssql_ops</a><div class="text-secondary small">SQL Server operations</div></div></div></td>
            <td><span class="badge bg-azure-lt">SQL Server</span></td>
            <td><div class="d-flex flex-wrap gap-1"><span class="badge bg-green-lt">Dev</span><span class="badge bg-azure-lt">Stg</span><span class="badge bg-purple-lt">Prd</span></div></td>
            <td><span class="badge bg-green">Active</span></td>
            <td class="text-nowrap"><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="pencil"></i></a></td></tr>
          <tr><td><div class="d-flex align-items-center gap-2"><span class="avatar avatar-sm rounded bg-orange-lt text-orange"><i data-lucide="database"></i></span>
            <div><a class="text-reset d-block">mysql_app</a><div class="text-secondary small">MySQL application</div></div></div></td>
            <td><span class="badge bg-orange-lt">MySQL</span></td>
            <td><div class="d-flex flex-wrap gap-1"><span class="badge bg-green-lt">Dev</span><span class="badge bg-azure-lt">Stg</span><span class="badge bg-secondary-lt">Prd</span></div></td>
            <td><span class="badge bg-green">Active</span></td>
            <td class="text-nowrap"><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="pencil"></i></a></td></tr>
        </tbody>
      </table></div>
    </div></div></div>`,
  ),

  deployments: chrome(
    "deployments",
    `<div class="page-header d-print-none"><div class="container-xl"><div class="row g-2 align-items-center">
      <div class="col"><h2 class="page-title">Deployments</h2></div>
      <div class="col-auto ms-auto d-flex gap-2">
        <a class="btn btn-ghost-secondary"><i data-lucide="archive" class="me-1"></i>Archived</a>
        <button class="btn btn-primary"><i data-lucide="plus" class="me-2"></i>Create deployment</button>
      </div>
    </div></div></div>
    <div class="page-body"><div class="container-xl"><div class="card">
      <div class="card-header"><form class="querial-list-filters">
        <div class="querial-list-filters-search"><i data-lucide="search"></i>
          <input class="querial-list-filters-input" placeholder="Search by name or code…" /></div>
      </form></div>
      <div class="card-body p-0"><table class="table table-vcenter card-table">
        <thead><tr><th>Deployment name</th><th>Pipeline</th><th>Version</th><th>Environment</th><th>Status</th><th>Time zone</th><th class="w-1">Actions</th></tr></thead>
        <tbody>
          <tr><td><a href="#">daily_kpis / production</a></td>
            <td><span class="text-muted small">daily_kpis</span><br/>Daily KPIs</td>
            <td><span class="badge bg-blue-lt">v4</span></td>
            <td class="text-muted small">Production</td>
            <td><span class="badge bg-green-lt">Active</span></td>
            <td class="text-muted small">UTC</td>
            <td class="text-nowrap"><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="eye"></i></a></td></tr>
          <tr><td><a href="#">daily_kpis / staging</a></td>
            <td><span class="text-muted small">daily_kpis</span><br/>Daily KPIs</td>
            <td><span class="badge bg-blue-lt">v4</span></td>
            <td class="text-muted small">Staging</td>
            <td><span class="badge bg-green-lt">Active</span></td>
            <td class="text-muted small">UTC</td>
            <td class="text-nowrap"><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="eye"></i></a></td></tr>
          <tr><td><a href="#">cross_db_sync / development</a></td>
            <td><span class="text-muted small">cross_db_sync</span><br/>Cross-database sync</td>
            <td><span class="badge bg-blue-lt">v2</span></td>
            <td class="text-muted small">Development</td>
            <td><span class="badge bg-green-lt">Active</span></td>
            <td class="text-muted small">Europe/Berlin</td>
            <td class="text-nowrap"><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="eye"></i></a></td></tr>
        </tbody>
      </table></div>
    </div></div></div>`,
  ),

  operations: chrome(
    "runs",
    `<div class="page-header d-print-none"><div class="container-xl"><div class="row g-2 align-items-center">
      <div class="col"><h2 class="page-title">Run history</h2><div class="page-pretitle">Scheduled and manual executions</div></div>
    </div></div></div>
    <div class="page-body"><div class="container-xl"><div class="card">
      <div class="card-header"><form class="querial-list-filters">
        <div class="querial-list-filters-search"><i data-lucide="search"></i>
          <input class="querial-list-filters-input" placeholder="Search runs…" /></div>
        <div class="querial-list-filters-controls">
          <div class="querial-list-filters-field"><label>Environment</label>
            <select class="form-select querial-list-filters-select"><option>All environments</option></select></div>
          <div class="querial-list-filters-field"><label>Status</label>
            <select class="form-select querial-list-filters-select"><option>All statuses</option></select></div>
        </div>
      </form></div>
      <div class="card-body p-0"><table class="table table-vcenter card-table">
        <thead><tr><th>Deployment</th><th class="w-1">Actions</th><th>Status</th><th>Environment</th><th>Trigger</th><th>Started</th><th>Duration</th></tr></thead>
        <tbody>
          <tr><td>daily_kpis / production</td>
            <td><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="git-fork"></i></a></td>
            <td><span class="badge bg-green-lt">Succeeded</span></td>
            <td>Production</td><td>Schedule</td><td class="text-muted small">08:00:02</td><td>1m 12s</td></tr>
          <tr><td>daily_kpis / production</td>
            <td><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="git-fork"></i></a></td>
            <td><span class="badge bg-azure-lt">Running</span></td>
            <td>Production</td><td>Schedule</td><td class="text-muted small">09:00:01</td><td>—</td></tr>
          <tr><td>cross_db_sync / development</td>
            <td><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="rotate-cw"></i></a></td>
            <td><span class="badge bg-red-lt">Failed</span></td>
            <td>Development</td><td>Manual</td><td class="text-muted small">08:41:18</td><td>22s</td></tr>
          <tr><td>daily_kpis / staging</td>
            <td><a class="btn btn-sm btn-icon btn-ghost-secondary"><i data-lucide="git-fork"></i></a></td>
            <td><span class="badge bg-green-lt">Succeeded</span></td>
            <td>Staging</td><td>Promote</td><td class="text-muted small">07:12:44</td><td>58s</td></tr>
        </tbody>
      </table></div>
    </div></div></div>`,
  ),

  "dag-designer": chrome(
    "pipelines",
    `<div class="page-body page-body-fullbleed dag-designer-workspace">
      <div class="page-header d-print-none px-3"><div class="row g-2 align-items-center">
        <div class="col">
          <div class="page-pretitle">Pipelines <span class="mx-1">›</span> Daily KPIs</div>
          <h2 class="page-title"><i data-lucide="git-fork" class="me-2"></i>DAG Designer
            <span class="badge bg-blue-lt ms-2">daily_kpis</span>
            <small class="text-muted ms-2 fw-normal" style="font-size:0.8rem">Draft r12</small>
          </h2>
        </div>
        <div class="col-auto ms-auto d-flex gap-2">
          <button class="btn btn-ghost-secondary btn-sm"><i data-lucide="plus" class="me-1"></i>Add step</button>
          <button class="btn btn-ghost-secondary btn-sm"><i data-lucide="database" class="me-1"></i>Add migration</button>
          <button class="btn btn-primary btn-sm"><i data-lucide="upload" class="me-1"></i>Publish</button>
        </div>
      </div></div>
      <div class="px-3 pb-3" style="height:calc(100vh - 7.5rem);display:flex;flex-direction:column">
        <div class="dag-canvas">
          <svg style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none">
            <path d="M 300 118 C 380 118, 380 118, 460 118" stroke="#3451B2" stroke-width="2" fill="none"/>
            <path d="M 680 118 C 760 90, 760 90, 840 90" stroke="#3451B2" stroke-width="2" fill="none"/>
            <path d="M 680 118 C 760 200, 760 200, 840 200" stroke="#3451B2" stroke-width="2" fill="none"/>
          </svg>
          <div class="dag-node" style="left:88px;top:72px">
            <div class="text-muted small">Root · sql_query</div>
            <div class="fw-semibold">extract_orders</div>
            <div class="text-secondary small">pg_analytics</div>
          </div>
          <div class="dag-node" style="left:468px;top:72px">
            <div class="text-muted small">artifact-sql</div>
            <div class="fw-semibold">transform_kpis</div>
            <div class="text-secondary small">DuckDB</div>
          </div>
          <div class="dag-node" style="left:848px;top:44px">
            <div class="text-muted small">staged-database-sql</div>
            <div class="fw-semibold">sink_postgres</div>
            <div class="text-secondary small">pg_analytics</div>
          </div>
          <div class="dag-node" style="left:848px;top:154px">
            <div class="text-muted small">staged-database-sql</div>
            <div class="fw-semibold">sink_sqlserver</div>
            <div class="text-secondary small">mssql_ops</div>
          </div>
        </div>
      </div>
    </div>`,
    `<link rel="stylesheet" href="/css/dag-designer.css" />`,
  ),

  "sql-editor": chrome(
    "sql",
    `<div class="page-body page-body-fullbleed sql-editor-workspace">
      <div class="page-header d-print-none px-3"><div class="row g-2 align-items-center">
        <div class="col">
          <h2 class="page-title">SQL Editor</h2>
          <div class="page-pretitle d-flex align-items-center gap-2">Pipeline step · transform_kpis
            <span class="badge bg-secondary-lt">transform_kpis</span>
            <small class="text-muted">Draft r12</small>
            <span class="badge bg-blue-lt">Development</span>
          </div>
        </div>
      </div></div>
      <div class="sql-editor-shell">
        <div class="card sql-editor-main-card">
          <div class="card-header">
            <div class="d-flex flex-wrap align-items-center gap-2">
              <span class="badge bg-blue-lt">PostgreSQL</span>
              <span class="text-muted small">pg_analytics</span>
              <button class="btn btn-sm btn-ghost-secondary ms-auto"><i data-lucide="play" class="me-1"></i>Preview</button>
              <button class="btn btn-sm btn-primary"><i data-lucide="save" class="me-1"></i>Save draft</button>
            </div>
          </div>
          <div class="sql-fake"><span class="sql-cm">-- Merge staged KPIs; tokens resolve at runtime</span>
<span class="sql-kw">INSERT INTO</span> reporting.daily_kpis (day, orders, revenue)
<span class="sql-kw">SELECT</span>
    date_trunc(<span class="sql-str">'day'</span>, o.created_at) <span class="sql-kw">AS</span> day,
    count(*) <span class="sql-kw">AS</span> orders,
    sum(o.amount) <span class="sql-kw">AS</span> revenue
<span class="sql-kw">FROM</span> { input.orders } o
<span class="sql-kw">GROUP BY</span> 1
<span class="sql-kw">ON CONFLICT</span> (day) <span class="sql-kw">DO UPDATE SET</span>
    orders = excluded.orders,
    revenue = excluded.revenue;</div>
        </div>
      </div>
    </div>`,
    `<link rel="stylesheet" href="/css/sql-editor.css" />`,
  ),

  "run-visualizer": chrome(
    "runs",
    `<div class="page-body page-body-fullbleed dag-designer-workspace">
      <div class="page-header d-print-none px-3"><div class="row g-2 align-items-center">
        <div class="col">
          <div class="page-pretitle">Run history <span class="mx-1">›</span> daily_kpis / production</div>
          <h2 class="page-title"><i data-lucide="activity" class="me-2"></i>Run visualizer
            <span class="badge bg-green-lt ms-2">Succeeded</span>
            <span class="badge bg-blue-lt">v4</span>
          </h2>
        </div>
      </div></div>
      <div class="px-3 pb-3" style="height:calc(100vh - 7.5rem);display:flex;flex-direction:column">
        <div class="dag-canvas">
          <svg style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none">
            <path d="M 300 118 C 380 118, 380 118, 460 118" stroke="#2fb344" stroke-width="2" fill="none"/>
            <path d="M 680 118 C 760 90, 760 90, 840 90" stroke="#2fb344" stroke-width="2" fill="none"/>
            <path d="M 680 118 C 760 200, 760 200, 840 200" stroke="#2fb344" stroke-width="2" fill="none"/>
          </svg>
          <div class="dag-node" style="left:88px;top:72px;border-color:#2fb344">
            <span class="badge bg-green-lt mb-1">Succeeded</span>
            <div class="fw-semibold">extract_orders</div>
            <div class="text-secondary small">1.2s · 48,102 rows</div>
          </div>
          <div class="dag-node" style="left:468px;top:72px;border-color:#2fb344">
            <span class="badge bg-green-lt mb-1">Succeeded</span>
            <div class="fw-semibold">transform_kpis</div>
            <div class="text-secondary small">3.4s · DuckDB</div>
          </div>
          <div class="dag-node" style="left:848px;top:44px;border-color:#2fb344">
            <span class="badge bg-green-lt mb-1">Succeeded</span>
            <div class="fw-semibold">sink_postgres</div>
            <div class="text-secondary small">0.8s · staged SQL</div>
          </div>
          <div class="dag-node" style="left:848px;top:154px;border-color:#2fb344">
            <span class="badge bg-green-lt mb-1">Succeeded</span>
            <div class="fw-semibold">sink_sqlserver</div>
            <div class="text-secondary small">1.1s · staged SQL</div>
          </div>
        </div>
      </div>
    </div>`,
  ),
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const url = new URL(req.url, "http://127.0.0.1");
      if (url.pathname.startsWith("/shot/")) {
        const id = url.pathname.slice("/shot/".length).replace(/\.html$/, "");
        const html = pages[id];
        if (!html) {
          res.writeHead(404);
          res.end("missing");
          return;
        }
        res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
        res.end(html);
        return;
      }
      const rel = decodeURIComponent(url.pathname);
      const file = path.join(webRoot, rel);
      if (!file.startsWith(webRoot) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        res.writeHead(404);
        res.end();
        return;
      }
      const ext = path.extname(file);
      res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(0, "127.0.0.1", () => resolve(server));
  });
}

const shots = [
  "dag-designer",
  "sql-editor",
  "run-visualizer",
  "deployments",
  "connections",
  "operations",
];

const server = await startServer();
const port = server.address().port;
fs.mkdirSync(outDir, { recursive: true });

const channels = [
  process.env.PLAYWRIGHT_CHANNEL,
  "chrome",
  "msedge",
].filter((c, i, all) => c && all.indexOf(c) === i);

let browser;
let lastError;
for (const channel of channels) {
  try {
    browser = await chromium.launch({ headless: true, channel });
    console.log("using browser channel", channel);
    break;
  } catch (err) {
    lastError = err;
    console.warn(`channel ${channel} failed:`, err.message.split("\n")[0]);
  }
}
if (!browser) {
  throw lastError ?? new Error("No browser channel launched");
}
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  deviceScaleFactor: 2,
});
const page = await context.newPage();

for (const id of shots) {
  await page.goto(`http://127.0.0.1:${port}/shot/${id}.html`, {
    waitUntil: "networkidle",
  });
  await page.waitForTimeout(400);

  await page.evaluate(() => {
    document.body.setAttribute("data-bs-theme", "light");
  });
  await page.screenshot({
    path: path.join(outDir, `${id}-light.png`),
    type: "png",
  });

  await page.evaluate(() => {
    document.body.setAttribute("data-bs-theme", "dark");
  });
  await page.screenshot({
    path: path.join(outDir, `${id}-dark.png`),
    type: "png",
  });
  console.log("captured", id);
}

await browser.close();
server.close();
console.log("wrote", outDir);

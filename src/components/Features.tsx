import { motion } from "framer-motion";
import {
  FileCode,
  GitBranch,
  Database,
  CalendarClock,
  Bot,
  Package,
  Upload,
  Sparkles,
} from "lucide-react";

const features = [
  {
    icon: FileCode,
    title: "SQL stays the language",
    description:
      "Author PostgreSQL, T-SQL, or MySQL. Window functions, CTEs, MERGE, provider bulk APIs — whatever the dialect needs. Querial does not invent a metric DSL.",
    gradient: "from-querial-indigo to-querial-indigo-on-dark",
  },
  {
    icon: GitBranch,
    title: "Immutable published DAGs",
    description:
      "A draft is editable. A published version is an immutable graph: edges, layouts, retry policy, and SQL frozen together. Operators deploy versions, not live edits.",
    spec: "Structural roots only",
    gradient: "from-querial-indigo-on-dark to-querial-sky",
  },
  {
    icon: Database,
    title: "Design once, deploy many",
    description:
      "One version binds to Development, Staging, and Production through logical connections. Each kind has its own encrypted endpoint. Tenant A failing does not rewrite tenant B's version.",
    gradient: "from-querial-sky to-querial-indigo",
  },
  {
    icon: CalendarClock,
    title: "Scheduler creates; agents pull",
    description:
      "The first-party scheduler persists due work and creates runs. Registered agents heartbeat, join pools, and pull leases. Querial owns assignment. Cron never executes SQL.",
    gradient: "from-querial-indigo to-querial-sky",
  },
  {
    icon: Bot,
    title: "Artifacts without hiding SQL",
    description:
      "Parquet on local disk or S3. DuckDB embedded in eligible agents. Canvas edges bind inbound files; packages use a list of from_step rows, not a YAML map. The only database sink is Staged Database SQL — bulk-load, then your merge SQL. There is no ArtifactToTable.",
    spec: "No row-by-row Dapper loads",
    gradient: "from-querial-indigo-on-dark to-querial-indigo",
  },
  {
    icon: Upload,
    title: "Ingest files; trigger by API",
    description:
      "An external-parquet root starts a DAG from a file you already have. POST /api/trigger accepts parameters and multipart Parquet. Schedules cannot attach files. Project- or deployment-scoped keys, hashed at rest.",
    spec: "JSON or multipart",
    gradient: "from-querial-sky to-querial-indigo",
  },
  {
    icon: Sparkles,
    title: "SQL Assist, grounded in schema",
    description:
      "Generate dialect SQL against a schema source — not the runtime endpoint. Send drafts; humans review and publish. Embeddings live on PostgreSQL 18 with pgvector. Secrets never enter prompts.",
    spec: "Draft only",
    gradient: "from-querial-indigo to-querial-indigo-on-dark",
  },
  {
    icon: Package,
    title: "Packages without secrets",
    description:
      "Export YAML + SQL trees as querial.package/v1. Codes are identity. Connection and schema-source stubs list names and providers only. Import remaps endpoints; ciphertext never travels in the tree. Git is optional.",
    gradient: "from-querial-sky to-querial-indigo-on-dark",
  },
];

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 },
};

export function Features() {
  return (
    <section id="features" className="py-20 md:py-32">
      <div className="container mx-auto px-4">
        <div className="text-center space-y-4 mb-16">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="text-3xl md:text-5xl font-bold"
          >
            Built around{" "}
            <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
              SQL you already write
            </span>
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-lg text-muted-foreground max-w-2xl mx-auto"
          >
            Versioning, deployment, scheduling, and audit — without hiding the dialect.
          </motion.p>
        </div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
        >
          {features.map((feature, index) => {
            const Icon = feature.icon;
            return (
              <motion.div
                key={index}
                variants={item}
                className="group relative p-6 rounded-2xl border border-border/50 bg-card/50 backdrop-blur-sm hover:shadow-lg hover:shadow-querial-indigo/5 transition-all duration-300 hover:-translate-y-1"
              >
                <div
                  className={`inline-flex p-3 rounded-xl bg-gradient-to-br ${feature.gradient} mb-4`}
                >
                  <Icon className="h-6 w-6 text-white" />
                </div>
                <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                <p className="text-muted-foreground text-sm leading-relaxed">
                  {feature.description}
                </p>
                {feature.spec && (
                  <span className="inline-block mt-3 text-xs font-mono text-querial-sky/70 bg-querial-sky/10 px-2 py-0.5 rounded">
                    {feature.spec}
                  </span>
                )}
              </motion.div>
            );
          })}
        </motion.div>
      </div>
    </section>
  );
}

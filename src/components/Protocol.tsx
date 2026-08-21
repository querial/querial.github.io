import { motion } from "framer-motion";
import {
    LayoutDashboard,
    Server,
    Database,
    Bot,
    HardDrive,
    Layers,
} from "lucide-react";

const layers = [
    {
        icon: LayoutDashboard,
        name: "Workspace and Administration",
        description:
            "Browser MVC. Workspace is pipelines, SQL, and runs. Administration is the team factory, invites, inspector, users, and AI. No application-level top bar — navigation lives in the left sidebar.",
        color: "text-querial-indigo-on-dark",
    },
    {
        icon: Server,
        name: "Platform API",
        description:
            "Separate API host. Session cookies or a project- or deployment-bound API key. Mutating verbs require CSRF for cookie callers. Keys never act as Platform admin. POST /api/trigger accepts parameters and multipart Parquet.",
        color: "text-querial-sky",
    },
    {
        icon: Database,
        name: "Control database",
        description:
            "PostgreSQL 18 with pgvector. Dapper only — no object-relational mapper. Numbered SQL migrations. Connection secrets at rest with AES-256-GCM.",
        color: "text-querial-indigo",
    },
    {
        icon: Bot,
        name: "Workers and registered agents",
        description:
            "Dedicated worker by default; in-process optional. Agents register, heartbeat, join pools, and pull leases. Feature flags keep legacy serial execution until DAG/agents are on.",
        color: "text-querial-indigo-on-dark",
    },
    {
        icon: HardDrive,
        name: "Targets and artifacts",
        description:
            "PostgreSQL, SQL Server, and MySQL. Target-local migration history is authoritative. Parquet on local disk or S3. DuckDB embedded in eligible agents. No distributed transactions across connections.",
        color: "text-querial-sky",
    },
];

export function Architecture() {
    return (
        <section id="architecture" className="py-20 md:py-32 bg-muted/30">
            <div className="container mx-auto px-4">
                <div className="flex flex-col lg:flex-row items-center gap-16">
                    <div className="flex-1 space-y-6">
                        <motion.div
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.5 }}
                        >
                            <div className="inline-flex items-center gap-2 rounded-full border border-querial-sky/30 bg-querial-sky/10 px-3 py-1 text-xs font-medium text-querial-sky">
                                <Layers className="h-3 w-3" />
                                Control plane
                            </div>
                        </motion.div>

                        <motion.h2
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.5, delay: 0.1 }}
                            className="text-3xl md:text-5xl font-bold"
                        >
                            Execute on the{" "}
                            <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
                                target
                            </span>
                            , audit in the plane
                        </motion.h2>

                        <motion.p
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.5, delay: 0.2 }}
                            className="text-lg text-muted-foreground leading-relaxed max-w-xl"
                        >
                            Querial is not a hidden query engine. Steps and migrations run
                            inside each target database. The control plane stores versions,
                            deployments, leases, runs, and lineage — not the business rows.
                        </motion.p>

                        <motion.p
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.5, delay: 0.25 }}
                            className="text-muted-foreground leading-relaxed max-w-xl"
                        >
                            Git is optional and never required to run a pipeline. Messaging
                            is optional and never carries Parquet. APIs never return
                            decrypted secrets.
                        </motion.p>
                    </div>

                    <motion.div
                        initial={{ opacity: 0, x: 30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.6, delay: 0.2 }}
                        className="flex-1 w-full max-w-md"
                    >
                        <div className="space-y-2">
                            {layers.map((layer, index) => (
                                <motion.div
                                    key={layer.name}
                                    initial={{ opacity: 0, x: 20 }}
                                    whileInView={{ opacity: 1, x: 0 }}
                                    viewport={{ once: true }}
                                    transition={{ duration: 0.3, delay: 0.3 + index * 0.08 }}
                                    className="flex items-start gap-4 p-3 rounded-lg border border-border/30 bg-card/30 backdrop-blur-sm hover:bg-card/60 transition-colors"
                                >
                                    <layer.icon className={`h-4 w-4 mt-0.5 shrink-0 ${layer.color}`} />
                                    <div>
                                        <span className={`text-sm font-medium ${layer.color}`}>
                                            {layer.name}
                                        </span>
                                        <p className="text-xs text-muted-foreground mt-0.5 leading-relaxed">
                                            {layer.description}
                                        </p>
                                    </div>
                                </motion.div>
                            ))}
                        </div>
                    </motion.div>
                </div>
            </div>
        </section>
    );
}

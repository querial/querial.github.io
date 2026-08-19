import { motion } from "framer-motion";
import { CheckCircle2, Clock, Circle } from "lucide-react";

const roadmapItems = [
    {
        title: "SQL-native pipelines and publish",
        description:
            "Drafts, immutable versions, dialect SQL, target-local migrations, logical connections with Development / Staging / Production endpoints.",
        status: "done",
    },
    {
        title: "DAG designer and run visualizer",
        description:
            "Visual graph editing with cycle rejection, structural roots, and live run status on the published graph.",
        status: "done",
    },
    {
        title: "Scheduling, agents, and leases",
        description:
            "First-party scheduler creates runs. Registered agents pull leases from project-scoped pools. Dual-path keeps legacy serial until flags are on.",
        status: "done",
    },
    {
        title: "Artifacts, DuckDB, Staged Database SQL",
        description:
            "Parquet, S3 or local store, embedded DuckDB, provider bulk load, developer merge SQL. No ArtifactToTable.",
        status: "done",
    },
    {
        title: "Packages, optional Git, API keys",
        description:
            "querial.package/v1 export/import, optional Git remotes, project-bound API keys with hashed secrets and idempotent run triggers.",
        status: "done",
    },
    {
        title: "Teams, projects, and RBAC",
        description:
            "Platform / Team / Project layers. Developer, DevOps, and Project admin. Invite attaches memberships immediately. Access Inspector is read-only.",
        status: "done",
    },
    {
        title: "In-run retry and failed-cone recovery",
        description:
            "Policy snapshot at plan create. Cone retry rebinds succeeded artifacts. Developers cannot retry.",
        status: "done",
    },
    {
        title: "Need-to-know inside a team",
        description:
            "Team admin currently inherits Project admin on every project in the team. Finer intra-team isolation is later, if a department splits is not enough.",
        status: "planned",
    },
];

const statusConfig: Record<
    string,
    { label: string; color: string; icon: typeof Clock }
> = {
    done: { label: "Done", color: "text-querial-sky", icon: CheckCircle2 },
    "in-progress": { label: "In progress", color: "text-querial-indigo-on-dark", icon: Clock },
    planned: { label: "Planned", color: "text-muted-foreground", icon: Circle },
};

export function Roadmap() {
    return (
        <section id="roadmap" className="py-20 md:py-32 bg-muted/30">
            <div className="container mx-auto px-4">
                <div className="text-center space-y-4 mb-16">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5 }}
                        className="text-3xl md:text-5xl font-bold"
                    >
                        What's{" "}
                        <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
                            in the product
                        </span>
                    </motion.h2>
                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5, delay: 0.1 }}
                        className="text-lg text-muted-foreground max-w-2xl mx-auto"
                    >
                        Core control-plane capabilities are shipped. Nested teams and
                        org-wide agent sharing are out of scope until a later decision.
                    </motion.p>
                </div>

                <div className="max-w-3xl mx-auto">
                    <div className="relative">
                        <div className="absolute left-6 top-0 bottom-0 w-px bg-gradient-to-b from-querial-indigo-on-dark via-querial-sky to-transparent" />

                        {roadmapItems.map((roadmapItem, index) => {
                            const status = statusConfig[roadmapItem.status];
                            const StatusIcon = status.icon;

                            return (
                                <motion.div
                                    key={index}
                                    initial={{ opacity: 0, x: -20 }}
                                    whileInView={{ opacity: 1, x: 0 }}
                                    viewport={{ once: true }}
                                    transition={{ duration: 0.5, delay: index * 0.1 }}
                                    className="relative pl-16 pb-10 last:pb-0"
                                >
                                    <div className="absolute left-3.5 top-1 w-5 h-5 rounded-full bg-background border-2 border-querial-indigo-on-dark flex items-center justify-center">
                                        <div className={`w-2 h-2 rounded-full ${roadmapItem.status === "in-progress" ? "bg-querial-sky animate-pulse" : roadmapItem.status === "done" ? "bg-querial-sky" : "bg-muted-foreground/40"
                                            }`} />
                                    </div>

                                    <div className="p-6 rounded-2xl border border-border/50 bg-card/50 backdrop-blur-sm">
                                        <div className="flex-1">
                                            <div className="flex items-center gap-3 mb-2">
                                                <h3 className="text-lg font-semibold">
                                                    {roadmapItem.title}
                                                </h3>
                                                <span className={`inline-flex items-center gap-1 text-xs font-medium ${status.color}`}>
                                                    <StatusIcon className="h-3 w-3" />
                                                    {status.label}
                                                </span>
                                            </div>
                                            <p className="text-sm text-muted-foreground leading-relaxed">
                                                {roadmapItem.description}
                                            </p>
                                        </div>
                                    </div>
                                </motion.div>
                            );
                        })}
                    </div>
                </div>
            </div>
        </section>
    );
}

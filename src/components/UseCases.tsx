import { motion } from "framer-motion";
import {
    Code2,
    ServerCog,
    FolderKanban,
    Users,
    Shield,
} from "lucide-react";

const personas = [
    {
        icon: Code2,
        title: "Developer",
        layer: "Project role",
        description:
            "Author drafts, DAG edges, steps, and migrations. Use the SQL workspace and SQL Assist against a schema source; Run is Development only. Assist drafts; it never publishes. Packages export SQL without secrets. External-parquet roots are designed here; operators trigger them with files.",
        example: "Workspace → Pipelines → DAG designer → SQL workspace",
        gradient: "from-querial-indigo to-querial-indigo-on-dark",
    },
    {
        icon: ServerCog,
        title: "DevOps",
        layer: "Project role",
        description:
            "Operate: connections, deployments, schedules, agents, Git remotes, API keys, and runs. Trigger via JSON or multipart Parquet. SQL preview may target any environment kind. Promote to Staging. Production promote and approval are not this role. Retry and failed-cone recovery are.",
        example: "Deploy → Schedule → Agents pull leases → Retry cone",
        gradient: "from-querial-sky to-querial-indigo",
    },
    {
        icon: FolderKanban,
        title: "Project admin",
        layer: "Project role",
        description:
            "Includes design and operate, plus project membership for people already on the team. Production promote and approval. Cannot create Identity logins or new projects. Isolation is this project — catalogs from other projects 404.",
        example: "Members · Production promote · Approve",
        gradient: "from-querial-indigo-on-dark to-querial-sky",
    },
    {
        icon: Users,
        title: "Team admin",
        layer: "Team flag",
        description:
            "Creates and archives projects in that team, invites into the team, and is treated as Project admin on every project in the team. Cannot grant Platform admin or invite another team. Administration shell is the home for this work.",
        example: "Administration → Projects · Invite · Access Inspector",
        gradient: "from-querial-indigo to-querial-sky",
    },
    {
        icon: Shield,
        title: "Platform admin",
        layer: "Instance role",
        description:
            "Users, teams, AI configuration, break-glass. May act in any team or project without membership, still picking a current project in the UI. Only this role grants Platform admin. First Setup creates this login on an empty instance.",
        example: "Setup → Users · Teams · AI config",
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

export function UseCases() {
    return (
        <section id="personas" className="py-20 md:py-32">
            <div className="container mx-auto px-4">
                <div className="text-center space-y-4 mb-16">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5 }}
                        className="text-3xl md:text-5xl font-bold"
                    >
                        One instance,{" "}
                        <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
                            five duties
                        </span>
                    </motion.h2>
                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5, delay: 0.1 }}
                        className="text-lg text-muted-foreground max-w-2xl mx-auto"
                    >
                        Developer and DevOps are not a hierarchy. Isolation is the project,
                        not the team. Platform admin is the only Identity role.
                    </motion.p>
                </div>

                <motion.div
                    variants={container}
                    initial="hidden"
                    whileInView="show"
                    viewport={{ once: true }}
                    className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto"
                >
                    {personas.map((persona) => {
                        const Icon = persona.icon;
                        return (
                            <motion.div
                                key={persona.title}
                                variants={item}
                                className="group relative p-6 rounded-2xl border border-border/50 bg-card/50 backdrop-blur-sm hover:shadow-lg hover:shadow-querial-indigo/5 transition-all duration-300 hover:-translate-y-1"
                            >
                                <div
                                    className={`inline-flex p-3 rounded-xl bg-gradient-to-br ${persona.gradient} mb-4`}
                                >
                                    <Icon className="h-6 w-6 text-white" />
                                </div>
                                <p className="text-xs font-mono uppercase tracking-wider text-muted-foreground mb-1">
                                    {persona.layer}
                                </p>
                                <h3 className="text-lg font-semibold mb-2">{persona.title}</h3>
                                <p className="text-sm text-muted-foreground mb-3">
                                    {persona.description}
                                </p>
                                <div className="rounded-lg bg-gray-900/90 dark:bg-muted/50 border border-gray-800/50 dark:border-border/30 px-3 py-2">
                                    <code className="text-xs font-mono text-querial-sky">
                                        {persona.example}
                                    </code>
                                </div>
                            </motion.div>
                        );
                    })}
                </motion.div>
            </div>
        </section>
    );
}

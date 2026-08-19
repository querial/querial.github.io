import { motion } from "framer-motion";
import { Database, Server, Box } from "lucide-react";

const platforms = [
    { name: "PostgreSQL", icon: Database, kind: "target" as const },
    { name: "SQL Server", icon: Server, kind: "target" as const },
    { name: "MySQL", icon: Database, kind: "target" as const },
    { name: "Control DB", icon: Database, kind: "plane" as const },
    { name: "Docker", icon: Box, kind: "host" as const },
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

export function PlatformSupport() {
    return (
        <section id="platforms" className="py-16 md:py-24">
            <div className="container mx-auto px-4">
                <div className="text-center space-y-4 mb-12">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5 }}
                        className="text-3xl md:text-5xl font-bold"
                    >
                        Dialects stay{" "}
                        <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
                            honest
                        </span>
                    </motion.h2>
                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5, delay: 0.1 }}
                        className="text-lg text-muted-foreground max-w-2xl mx-auto"
                    >
                        A step's logical connection fixes the provider. Monaco and runtime
                        follow that provider. PostgreSQL SQL is not rewritten for SQL Server.
                    </motion.p>
                </div>

                <motion.div
                    variants={container}
                    initial="hidden"
                    whileInView="show"
                    viewport={{ once: true }}
                    className="grid grid-cols-2 md:grid-cols-5 gap-6 max-w-4xl mx-auto"
                >
                    {platforms.map((platform) => (
                        <motion.div
                            key={platform.name}
                            variants={item}
                            className="group flex flex-col items-center gap-3 p-6 rounded-2xl border border-border/50 bg-card/50 backdrop-blur-sm hover:shadow-lg hover:shadow-querial-indigo/5 transition-all duration-300 hover:-translate-y-1"
                        >
                            <div className="relative">
                                <div className="absolute inset-0 bg-gradient-to-br from-querial-indigo/20 to-querial-sky/10 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity" />
                                <div className="relative w-14 h-14 rounded-xl border border-border/50 bg-muted/40 flex items-center justify-center">
                                    <platform.icon className="h-6 w-6 text-querial-indigo-on-dark" />
                                </div>
                            </div>
                            <div className="text-center">
                                <p className="font-semibold text-sm">{platform.name}</p>
                                <p className="text-xs text-muted-foreground mt-0.5">
                                    {platform.kind === "target"
                                        ? "target"
                                        : platform.kind === "plane"
                                            ? "PostgreSQL 18 + pgvector"
                                            : "local compose"}
                                </p>
                            </div>
                        </motion.div>
                    ))}
                </motion.div>
            </div>
        </section>
    );
}

import { motion } from "framer-motion";
import { PenLine, Lock, Plug, Play, Activity } from "lucide-react";

const steps = [
    {
        icon: PenLine,
        number: "01",
        title: "Design",
        description:
            "Draft a pipeline in Workspace: steps, migrations, parameters, and DAG edges. SQL stays dialect-specific. The designer auto-saves; cycles are rejected before they persist.",
        color: "text-querial-indigo-on-dark",
        borderColor: "border-querial-indigo/30",
        bgColor: "bg-querial-indigo/10",
    },
    {
        icon: Lock,
        number: "02",
        title: "Publish",
        description:
            "Publishing freezes an immutable DAG. Further edits go to a new draft. You deploy versions, never live drafts. Structural roots are the only start nodes.",
        color: "text-querial-sky",
        borderColor: "border-querial-sky/30",
        bgColor: "bg-querial-sky/10",
    },
    {
        icon: Plug,
        number: "03",
        title: "Deploy",
        description:
            "Bind the same version to Development, Staging, or Production. Logical connections resolve to encrypted endpoints per kind. Parameters stay per deployment.",
        color: "text-querial-indigo",
        borderColor: "border-querial-indigo/30",
        bgColor: "bg-querial-indigo/10",
    },
    {
        icon: Play,
        number: "04",
        title: "Run",
        description:
            "Schedules create runs. Registered agents pull leases. Execution happens on the target database. Cron never assigns work; Querial does.",
        color: "text-querial-indigo-on-dark",
        borderColor: "border-querial-indigo/30",
        bgColor: "bg-querial-indigo/10",
    },
    {
        icon: Activity,
        number: "05",
        title: "Operate",
        description:
            "Watch the run visualizer, inspect logs, retry a failed cone without re-extracting succeeded Parquet, and promote only when Project admin approves Production.",
        color: "text-querial-sky",
        borderColor: "border-querial-sky/30",
        bgColor: "bg-querial-sky/10",
    },
];

export function HowItWorks() {
    return (
        <section id="how-it-works" className="relative py-20 md:py-32">
            <div className="absolute inset-0 -z-10" style={{ background: 'radial-gradient(ellipse 100% 100% at 50% 50%, hsl(var(--muted) / 0.4), transparent 75%)' }} />
            <div className="container mx-auto">
                <div className="text-center space-y-4 mb-16">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5 }}
                        className="text-3xl md:text-5xl font-bold"
                    >
                        How{" "}
                        <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
                            Querial
                        </span>{" "}
                        works
                    </motion.h2>
                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5, delay: 0.1 }}
                        className="text-lg text-muted-foreground max-w-2xl mx-auto"
                    >
                        Design → Publish → Deploy → Run → Operate. One loop around raw SQL, isolated per project.
                    </motion.p>
                </div>

                <div className="max-w-6xl mx-auto">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
                        {steps.map((step, index) => {
                            const Icon = step.icon;
                            return (
                                <motion.div
                                    key={index}
                                    initial={{ opacity: 0, y: 30 }}
                                    whileInView={{ opacity: 1, y: 0 }}
                                    viewport={{ once: true }}
                                    transition={{ duration: 0.5, delay: index * 0.15 }}
                                    className="relative"
                                >
                                    {index < steps.length - 1 && (
                                        <div className="hidden lg:block absolute top-12 left-full w-6 h-0.5 bg-gradient-to-r from-border to-transparent z-10" />
                                    )}

                                    <div
                                        className={`h-full p-6 rounded-2xl border ${step.borderColor} ${step.bgColor} backdrop-blur-sm`}
                                    >
                                        <div className="flex items-center gap-3 mb-4">
                                            <span className={`text-xs font-mono font-bold ${step.color} opacity-60`}>
                                                {step.number}
                                            </span>
                                            <div className={`p-2 rounded-lg ${step.bgColor}`}>
                                                <Icon className={`h-5 w-5 ${step.color}`} />
                                            </div>
                                        </div>

                                        <h3 className="text-lg font-semibold mb-2">{step.title}</h3>
                                        <p className="text-sm text-muted-foreground leading-relaxed">
                                            {step.description}
                                        </p>
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

import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Lightbox } from "@/components/Lightbox";

const screenshots = [
    {
        light: "/screenshots/desktop/dag-designer-light.png",
        dark: "/screenshots/desktop/dag-designer-dark.png",
        alt: "Querial — DAG designer",
        caption: "DAG designer",
        description: "Draft graph, palette, auto-layout, cycle checks",
    },
    {
        light: "/screenshots/desktop/sql-editor-light.png",
        dark: "/screenshots/desktop/sql-editor-dark.png",
        alt: "Querial — SQL workspace",
        caption: "SQL workspace",
        description: "Monaco, schema cache, Development-only for Developers",
    },
    {
        light: "/screenshots/desktop/run-visualizer-light.png",
        dark: "/screenshots/desktop/run-visualizer-dark.png",
        alt: "Querial — Run visualizer",
        caption: "Run visualizer",
        description: "Live status on the published graph",
    },
    {
        light: "/screenshots/desktop/deployments-light.png",
        dark: "/screenshots/desktop/deployments-dark.png",
        alt: "Querial — Deployments",
        caption: "Deployments",
        description: "Version + environment kind + parameters",
    },
    {
        light: "/screenshots/desktop/connections-light.png",
        dark: "/screenshots/desktop/connections-dark.png",
        alt: "Querial — Connections",
        caption: "Connections",
        description: "Logical name, provider, per-kind endpoints",
    },
    {
        light: "/screenshots/desktop/operations-light.png",
        dark: "/screenshots/desktop/operations-dark.png",
        alt: "Querial — Operations",
        caption: "Operations",
        description: "Runs, leases, retry, failed-cone recovery",
    },
];

export function ProductShowcase() {
    const [currentIndex, setCurrentIndex] = useState(0);
    const [lightboxOpen, setLightboxOpen] = useState(false);
    const [isDark, setIsDark] = useState(false);

    useEffect(() => {
        const root = document.documentElement;
        setIsDark(root.classList.contains("dark"));
        const observer = new MutationObserver(() => {
            setIsDark(root.classList.contains("dark"));
        });
        observer.observe(root, { attributes: true, attributeFilter: ["class"] });
        return () => observer.disconnect();
    }, []);

    const srcOf = (shot: (typeof screenshots)[number]) =>
        isDark ? shot.dark : shot.light;

    const nextSlide = useCallback(() => {
        setCurrentIndex((prev) => (prev + 1) % screenshots.length);
    }, []);

    const prevSlide = useCallback(() => {
        setCurrentIndex((prev) => (prev - 1 + screenshots.length) % screenshots.length);
    }, []);

    useEffect(() => {
        if (lightboxOpen) return;
        const interval = setInterval(nextSlide, 30000);
        return () => clearInterval(interval);
    }, [nextSlide, lightboxOpen]);

    const prev = (currentIndex - 1 + screenshots.length) % screenshots.length;
    const next = (currentIndex + 1) % screenshots.length;

    return (
        <section id="screenshots" className="py-20 md:py-32 overflow-hidden">
            <div className="container mx-auto px-4">
                <div className="text-center space-y-4 mb-16">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5 }}
                        className="text-3xl md:text-5xl font-bold"
                    >
                        Workspace,{" "}
                        <span className="bg-gradient-to-r from-querial-indigo to-querial-sky bg-clip-text text-transparent">
                            not a form farm
                        </span>
                    </motion.h2>
                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5, delay: 0.1 }}
                        className="text-lg text-muted-foreground max-w-2xl mx-auto"
                    >
                        The Workspace is a collapsible left sidebar, page headers in the
                        view, and modal create/edit for list entities. These captures use
                        the same Tabler shell as the app.
                    </motion.p>
                </div>

                <div className="flex items-center justify-center gap-4 md:gap-8 max-w-5xl mx-auto">
                    <motion.div
                        initial={{ opacity: 0, y: 40 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.6 }}
                        className="hidden md:flex flex-col items-center cursor-pointer"
                        onClick={prevSlide}
                    >
                        <img
                            src={srcOf(screenshots[prev])}
                            alt={screenshots[prev].alt}
                            className="w-48 md:w-56 rounded-xl shadow-xl border border-border/30 opacity-60 hover:opacity-80 transition-opacity bg-white dark:bg-zinc-900"
                        />
                        <p className="mt-3 font-semibold text-xs text-muted-foreground">{screenshots[prev].caption}</p>
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, y: 40 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.6, delay: 0.15 }}
                        className="relative flex flex-col items-center z-10"
                    >
                        <div className="absolute inset-0 bg-gradient-to-br from-querial-indigo/30 to-querial-sky/20 rounded-3xl blur-2xl scale-110 animate-pulse-glow" />
                        <div className="relative">
                            <AnimatePresence mode="wait">
                                <motion.img
                                    key={`${currentIndex}-${isDark}`}
                                    src={srcOf(screenshots[currentIndex])}
                                    alt={screenshots[currentIndex].alt}
                                    className="w-72 md:w-[28rem] rounded-2xl shadow-2xl shadow-querial-indigo/20 border border-border/30 cursor-pointer bg-white dark:bg-zinc-900"
                                    initial={{ opacity: 0, scale: 0.95 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    exit={{ opacity: 0, scale: 0.95 }}
                                    transition={{ duration: 0.3 }}
                                    onClick={() => setLightboxOpen(true)}
                                />
                            </AnimatePresence>
                        </div>
                        <div className="mt-4 text-center">
                            <p className="font-semibold text-sm">{screenshots[currentIndex].caption}</p>
                            <p className="text-xs text-muted-foreground">{screenshots[currentIndex].description}</p>
                        </div>
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, y: 40 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.6, delay: 0.3 }}
                        className="hidden md:flex flex-col items-center cursor-pointer"
                        onClick={nextSlide}
                    >
                        <img
                            src={srcOf(screenshots[next])}
                            alt={screenshots[next].alt}
                            className="w-48 md:w-56 rounded-xl shadow-xl border border-border/30 opacity-60 hover:opacity-80 transition-opacity bg-white dark:bg-zinc-900"
                        />
                        <p className="mt-3 font-semibold text-xs text-muted-foreground">{screenshots[next].caption}</p>
                    </motion.div>
                </div>

                <div className="flex items-center justify-center gap-4 mt-8">
                    <button
                        onClick={prevSlide}
                        className="p-2 rounded-full bg-querial-indigo/20 hover:bg-querial-indigo/40 transition-colors text-foreground"
                        aria-label="Previous screenshot"
                    >
                        <ChevronLeft className="h-5 w-5" />
                    </button>
                    <div className="flex gap-1.5">
                        {screenshots.map((_, index) => (
                            <button
                                key={index}
                                onClick={() => setCurrentIndex(index)}
                                className={`w-2 h-2 rounded-full transition-all ${index === currentIndex
                                    ? "bg-querial-sky w-5"
                                    : "bg-muted-foreground/30 hover:bg-muted-foreground/50"
                                    }`}
                                aria-label={`Go to screenshot ${index + 1}`}
                            />
                        ))}
                    </div>
                    <button
                        onClick={nextSlide}
                        className="p-2 rounded-full bg-querial-indigo/20 hover:bg-querial-indigo/40 transition-colors text-foreground"
                        aria-label="Next screenshot"
                    >
                        <ChevronRight className="h-5 w-5" />
                    </button>
                </div>
            </div>

            <Lightbox
                images={screenshots.map((s) => ({ src: srcOf(s), alt: s.alt, caption: s.caption }))}
                initialIndex={currentIndex}
                isOpen={lightboxOpen}
                onClose={() => setLightboxOpen(false)}
                variant="fullscreen"
            />
        </section>
    );
}

import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { GitBranch, Database, Play, ShieldCheck, ChevronLeft, ChevronRight } from "lucide-react";
import { Lightbox } from "@/components/Lightbox";

const heroScreenshots = [
  {
    light: "/screenshots/desktop/dag-designer-light.png",
    dark: "/screenshots/desktop/dag-designer-dark.png",
    alt: "Querial — DAG designer",
    caption: "DAG designer",
  },
  {
    light: "/screenshots/desktop/sql-editor-light.png",
    dark: "/screenshots/desktop/sql-editor-dark.png",
    alt: "Querial — SQL workspace",
    caption: "SQL workspace",
  },
  {
    light: "/screenshots/desktop/run-visualizer-light.png",
    dark: "/screenshots/desktop/run-visualizer-dark.png",
    alt: "Querial — Run visualizer",
    caption: "Run visualizer",
  },
  {
    light: "/screenshots/desktop/deployments-light.png",
    dark: "/screenshots/desktop/deployments-dark.png",
    alt: "Querial — Deployments",
    caption: "Deployments",
  },
  {
    light: "/screenshots/desktop/connections-light.png",
    dark: "/screenshots/desktop/connections-dark.png",
    alt: "Querial — Connections",
    caption: "Connections",
  },
  {
    light: "/screenshots/desktop/operations-light.png",
    dark: "/screenshots/desktop/operations-dark.png",
    alt: "Querial — Operations",
    caption: "Operations",
  },
];

const highlights = [
  {
    icon: GitBranch,
    label: "Design",
    desc: "Author dialect SQL as a DAG",
  },
  {
    icon: ShieldCheck,
    label: "Publish",
    desc: "Freeze an immutable version",
  },
  {
    icon: Database,
    label: "Deploy",
    desc: "Bind one version to many targets",
  },
  {
    icon: Play,
    label: "Operate",
    desc: "Schedule, lease, retry, audit",
  },
];

export function Hero() {
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

  const getImgSrc = (shot: (typeof heroScreenshots)[number]) =>
    isDark ? shot.dark : shot.light;

  const nextSlide = useCallback(() => {
    setCurrentIndex((prev) => (prev + 1) % heroScreenshots.length);
  }, []);

  const prevSlide = useCallback(() => {
    setCurrentIndex((prev) => (prev - 1 + heroScreenshots.length) % heroScreenshots.length);
  }, []);

  useEffect(() => {
    if (lightboxOpen) return;
    const interval = setInterval(nextSlide, 30000);
    return () => clearInterval(interval);
  }, [nextSlide, lightboxOpen]);

  return (
    <section className="relative py-20 md:py-32">
      <div className="absolute inset-0 -z-10 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-[60vw] h-[60vw] max-w-[50rem] max-h-[50rem] bg-querial-indigo/10 dark:bg-querial-indigo/15 rounded-full filter blur-[160px] animate-blob" />
        <div className="absolute -top-1/4 right-0 w-[60vw] h-[60vw] max-w-[50rem] max-h-[50rem] bg-querial-indigo-on-dark/10 dark:bg-querial-indigo-on-dark/10 rounded-full filter blur-[180px] animate-blob animation-delay-2000" />
        <div className="absolute -bottom-1/4 left-1/3 w-[50vw] h-[50vw] max-w-[40rem] max-h-[40rem] bg-querial-sky/5 dark:bg-querial-sky/10 rounded-full filter blur-[160px] animate-blob animation-delay-4000" />
      </div>

      <div className="container mx-auto px-4">
        <div className="flex flex-col lg:flex-row items-center gap-12 lg:gap-16">
          <div className="flex-1 flex flex-col items-center lg:items-start text-center lg:text-left space-y-8">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="flex flex-wrap items-center justify-center lg:justify-start gap-2"
            >
              <div className="inline-flex items-center gap-2 rounded-full border border-querial-indigo/30 bg-querial-indigo/10 dark:bg-querial-indigo/20 backdrop-blur-sm px-4 py-1.5 text-sm">
                <GitBranch className="h-4 w-4 text-querial-indigo-on-dark" />
                <span className="text-foreground/70 dark:text-muted-foreground font-semibold tracking-widest text-xs">
                  SQL-NATIVE CONTROL PLANE
                </span>
              </div>
              <div className="inline-flex items-center gap-2 rounded-full border border-querial-sky/30 bg-querial-sky/10 dark:bg-querial-sky/15 backdrop-blur-sm px-4 py-1.5 text-sm">
                <Database className="h-4 w-4 text-querial-sky" />
                <span className="text-foreground/70 dark:text-muted-foreground font-semibold tracking-widest text-xs">
                  POSTGRES · SQL SERVER · MYSQL
                </span>
              </div>
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight max-w-3xl"
            >
              You write the SQL.{" "}
              <span className="bg-gradient-to-r from-querial-indigo-on-dark via-querial-indigo to-querial-sky bg-clip-text text-transparent animate-gradient">
                Querial runs the rest.
              </span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.15 }}
              className="text-xs font-semibold text-querial-indigo-on-dark tracking-wider"
            >
              DESIGN ONCE. DEPLOY MANY. OPERATE FROM ONE PLACE.
            </motion.p>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="text-lg md:text-xl text-muted-foreground max-w-2xl leading-relaxed"
            >
              Querial is a self-hosted control plane for dialect-specific SQL.
              Developers author pipelines. DevOps deploy and operate them.
              Admins isolate work by team and project. The executable artifact
              is still SQL — never a metric DSL.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="grid grid-cols-2 md:grid-cols-4 gap-4 pt-4 w-full max-w-2xl"
            >
              {highlights.map((highlight, index) => {
                const Icon = highlight.icon;
                return (
                  <div key={index} className="flex flex-col items-center lg:items-start gap-1">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-mono text-muted-foreground/60">
                        {String(index + 1).padStart(2, "0")}
                      </span>
                      <Icon className="h-4 w-4 text-querial-sky" />
                    </div>
                    <p className="text-sm font-semibold">{highlight.label}</p>
                    <p className="text-xs text-muted-foreground">{highlight.desc}</p>
                  </div>
                );
              })}
            </motion.div>
          </div>

          <motion.div
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="flex-shrink-0 relative w-full max-w-xl"
          >
            <div className="absolute -inset-8 bg-querial-indigo/10 dark:bg-querial-indigo/20 rounded-full blur-[80px] animate-pulse-glow" />

            <div className="relative">
              <div className="overflow-hidden rounded-2xl shadow-xl shadow-querial-indigo/15 dark:shadow-querial-indigo/20 border border-querial-indigo/10 bg-white dark:bg-zinc-900">
                <AnimatePresence mode="wait">
                  <motion.img
                    key={`${currentIndex}-${isDark}`}
                    src={getImgSrc(heroScreenshots[currentIndex])}
                    alt={heroScreenshots[currentIndex].alt}
                    className="w-full cursor-pointer block"
                    initial={{ opacity: 0, x: 60 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -60 }}
                    transition={{ duration: 0.4 }}
                    onClick={() => setLightboxOpen(true)}
                  />
                </AnimatePresence>
              </div>
              <div className="flex items-center justify-center gap-4 mt-4">
                <button
                  onClick={prevSlide}
                  className="p-1.5 rounded-full bg-querial-indigo/20 hover:bg-querial-indigo/40 transition-colors text-foreground"
                  aria-label="Previous screenshot"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <div className="flex gap-2">
                  {heroScreenshots.map((_, index) => (
                    <button
                      key={index}
                      onClick={() => setCurrentIndex(index)}
                      className={`w-2 h-2 rounded-full transition-all ${index === currentIndex
                        ? "bg-querial-sky w-6"
                        : "bg-muted-foreground/30 hover:bg-muted-foreground/50"
                        }`}
                      aria-label={`Go to screenshot ${index + 1}`}
                    />
                  ))}
                </div>
                <button
                  onClick={nextSlide}
                  className="p-1.5 rounded-full bg-querial-indigo/20 hover:bg-querial-indigo/40 transition-colors text-foreground"
                  aria-label="Next screenshot"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      </div>

      <Lightbox
        images={heroScreenshots.map((s) => ({ src: getImgSrc(s), alt: s.alt, caption: s.caption }))}
        initialIndex={currentIndex}
        isOpen={lightboxOpen}
        onClose={() => setLightboxOpen(false)}
        variant="fullscreen"
      />
    </section>
  );
}

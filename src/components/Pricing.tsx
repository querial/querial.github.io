import { motion } from "framer-motion";
import { Check } from "lucide-react";

const reasons = [
  "You host the control plane and the targets",
  "Secrets stay AES-GCM encrypted; APIs never return plaintext",
  "Packages and Git remotes never carry connection strings",
];

export function FreeAndOpen() {
  return (
    <section id="self-hosted" className="py-20 md:py-32 bg-muted/30">
      <div className="container mx-auto px-4">
        <div className="max-w-2xl mx-auto text-center space-y-6">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="text-3xl md:text-5xl font-bold"
          >
            Self-hosted{" "}
            <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
              control plane.
            </span>
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-lg text-muted-foreground leading-relaxed"
          >
            Querial is not a SaaS that stores your tenant SQL. You run Web, API,
            and Worker against your PostgreSQL 18 control database. Target
            credentials never leave that plane in the clear. Isolation is the
            project: lists and gets outside the current project return not-found.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="p-8 rounded-2xl border border-border/50 bg-card text-left sm:inline-flex sm:flex-col sm:text-left"
          >
            <div className="space-y-3">
              {reasons.map((reason, i) => (
                <div key={i} className="flex items-start gap-3">
                  <Check className="h-5 w-5 text-querial-sky shrink-0 mt-0.5" />
                  <span className="text-sm text-muted-foreground">
                    {reason}
                  </span>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

import { motion } from "framer-motion";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

const faqs = [
  {
    question: "What is Querial?",
    answer:
      "Querial is a self-hosted, SQL-native control plane. You design versioned database pipelines, deploy them to one or many connections, execute steps inside each target database, and operate schedules and runs from Workspace. It is not a no-code ETL product, a streaming engine, or a replacement database.",
  },
  {
    question: "Does Querial replace SQL?",
    answer:
      "No. The saved executable artifact is dialect-specific SQL. Querial adds connection encryption, immutable published DAGs, target-local migration history, scheduling, registered agents, artifacts, and audit around that SQL.",
  },
  {
    question: "Who are Developers, DevOps, and admins?",
    answer:
      "Those are project and team duties, not a single Identity role. Project Developer designs against Development. Project DevOps operates and may SQL against any environment kind, but cannot promote Production. Project admin includes both plus membership and Production approval. Team admin is the project factory for that team and inherits Project admin on every project in it. Platform admin is the only Identity role and owns users, teams, and AI config.",
  },
  {
    question: "Which databases can a pipeline target?",
    answer:
      "PostgreSQL (including Timescale-style deployments), Microsoft SQL Server, and MySQL. The control database is PostgreSQL 18 with pgvector. A step's logical connection fixes the provider; dialects are not silently translated.",
  },
  {
    question: "Where do secrets live?",
    answer:
      "Target endpoints are encrypted at rest with AES-256-GCM. APIs never return decrypted secrets. Packages list logical connection names and providers only. API keys are hashed (SHA-256), shown once at creation, and bound to one project.",
  },
  {
    question: "Can I start a run from the middle of a DAG?",
    answer:
      "No. Structural roots — steps with no incoming edges — are the only start nodes. Default runs plan and execute the full published graph. Failed-cone recovery is a separate operator action on a failed or abandoned run: it still plans the full graph, skips execution of source succeeded nodes, and rebinds artifacts.",
  },
  {
    question: "Is Git required?",
    answer:
      "No. Packages can live in Git, and optional remotes can publish diffs, but core operation never requires a remote. Messaging is also optional and never carries large tabular payloads.",
  },
];

export function FAQ() {
  return (
    <section id="faq" className="py-20 md:py-32">
      <div className="container mx-auto px-4">
        <div className="text-center space-y-4 mb-16">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className="text-3xl md:text-5xl font-bold"
          >
            Frequently asked{" "}
            <span className="bg-gradient-to-r from-querial-indigo-on-dark to-querial-sky bg-clip-text text-transparent">
              questions
            </span>
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-lg text-muted-foreground max-w-2xl mx-auto"
          >
            The contract the product actually enforces
          </motion.p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="max-w-3xl mx-auto"
        >
          <Accordion type="single" collapsible className="w-full">
            {faqs.map((faq, index) => (
              <AccordionItem key={index} value={`item-${index}`}>
                <AccordionTrigger className="text-left">
                  {faq.question}
                </AccordionTrigger>
                <AccordionContent className="text-muted-foreground leading-relaxed">
                  {faq.answer}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </motion.div>
      </div>
    </section>
  );
}

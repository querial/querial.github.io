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
    question: "What is Wait any (when-any)?",
    answer:
      "On a step with two or more inbound edges, Wait all (the default) waits for every parent. Wait any starts after the first satisfied parent; losing branches keep running. It is control-only: Artifact SQL, Staged Database SQL, from_step bindings, and artifact_available edges cannot use it. Those are data joins and stay Wait all. Join mode is not a separate wait node on the canvas.",
  },
  {
    question: "Does Querial retry failed steps automatically?",
    answer:
      "Only when the published version raises retry_max_attempts above 1, the step is not marked unsafe for in-run auto-retry, and the failure is transient (deadlock, serialization, timeout). Default is one attempt — off. Writes default unsafe; extracts and Artifact SQL default safe. Exhausting in-run attempts does not start a failed-cone. Operators choose full retry or failed-cone on a failed or abandoned run. Developers set policy; they cannot click Retry.",
  },
  {
    question: "Is Git required?",
    answer:
      "No. Packages can live in Git, and optional remotes can commit and fetch trees, but core operation never requires a remote. Pipeline Publish in Workspace is separate from publish-to-Git. Messaging is also optional and never carries large tabular payloads. See Git and package remotes in the docs.",
  },
  {
    question: "Can a pipeline start from a Parquet file I already have?",
    answer:
      "Yes. An external-parquet step is a structural root with no SQL and no connection. You upload parquet.{outputName} on POST /api/trigger (multipart) or Web Run now. JSON-only trigger of an ingest version is 400. Cron cannot attach a file — those versions are not schedulable. AdventureWorks Scenario F is the teaching package.",
  },
  {
    question: "How do I bind Parquet files to Artifact SQL or a staged sink?",
    answer:
      "Draw an artifact_available edge from the producer. Packages store a list of from_step rows — map-shaped stages/inputs YAML is rejected. SQL uses {{ stage }} or {{ input }} when there is one inbound file, or {{ stage.outputName }} when there are several. Qualifiers are the producer output name, frozen when the edge is saved. Fill columns from upstream describe-shape or the last artifact; never FMTONLY on the sink SQL.",
  },
  {
    question: "How do I trigger a run from another system?",
    answer:
      "Mint a project- or deployment-scoped API key (qk_…). GET the trigger-contract, then POST /api/trigger with JSON parameters and, when needed, multipart Parquet parts. Idempotency is per project, deployment, and key for 24 hours. Assignment and pool JSON are not accepted.",
  },
  {
    question: "Does SQL Assist publish pipelines?",
    answer:
      "No. Send generates draft SQL against a schema source. Humans review, edit, and publish. Run uses a logical connection × environment, never the schema-source fetch string. Developers can execute Development only.",
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

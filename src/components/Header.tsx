import { useState, useRef, useEffect } from "react";
import { Menu, X, ChevronDown, Home } from "lucide-react";
import { ThemeToggle } from "@/components/ThemeToggle";
import { BrandLogo } from "@/components/BrandLogo";

const docsAudienceItems = [
  { label: "For Developers", href: "/docs#developers" },
  { label: "For DevOps", href: "/docs#devops" },
  { label: "For Project admins", href: "/docs#project-admins" },
  { label: "For Team admins", href: "/docs#team-admins" },
  { label: "For Platform admins", href: "/docs#platform-admins" },
];

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isDocsOpen, setIsDocsOpen] = useState(false);
  const docsRef = useRef<HTMLDivElement>(null);

  const sectionNavItems = [
    { label: "How it works", href: "/#how-it-works" },
    { label: "Features", href: "/#features" },
    { label: "Personas", href: "/#personas" },
    { label: "Labs", href: "/labs" },
  ];

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (docsRef.current && !docsRef.current.contains(event.target as Node)) {
        setIsDocsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/80 backdrop-blur-xl">
      <nav className="container flex min-h-20 h-20 md:h-[6.5rem] lg:h-28 items-center justify-between gap-2">
        <a href="/" className="flex items-center gap-3 min-w-0" aria-label="Querial home">
          <BrandLogo variant="header" />
        </a>

        <div className="hidden md:flex items-center space-x-8">
          <a
            href="/"
            className="text-muted-foreground hover:text-foreground transition-colors"
            aria-label="Home"
          >
            <Home className="h-4 w-4" />
          </a>
          {sectionNavItems.map((item) => (
            <a
              key={item.label}
              href={item.href}
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              {item.label}
            </a>
          ))}

          <div ref={docsRef} className="relative">
            <button
              onClick={() => setIsDocsOpen(!isDocsOpen)}
              className="flex items-center gap-1 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Docs
              <ChevronDown className={`h-3.5 w-3.5 transition-transform ${isDocsOpen ? "rotate-180" : ""}`} />
            </button>
            {isDocsOpen && (
              <div className="absolute right-0 top-full mt-2 w-56 rounded-xl border border-border/50 bg-background/95 backdrop-blur-xl shadow-lg shadow-black/10 py-2 z-50">
                {docsAudienceItems.map((item) => (
                  <a
                    key={item.label}
                    href={item.href}
                    className="flex items-center gap-3 px-3 py-2 text-sm text-muted-foreground hover:text-foreground hover:bg-muted/50 transition-colors"
                    onClick={() => setIsDocsOpen(false)}
                  >
                    {item.label}
                  </a>
                ))}
                <div className="border-t border-border/40 mt-1 pt-1">
                  <a
                    href="/docs"
                    className="flex items-center gap-2 px-3 py-2 text-sm text-link hover:text-foreground hover:bg-muted/50 transition-colors"
                    onClick={() => setIsDocsOpen(false)}
                  >
                    All docs →
                  </a>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="flex items-center gap-4 sm:gap-5">
          <ThemeToggle />

          <button
            className="md:hidden text-foreground"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            aria-label="Toggle menu"
          >
            {isMenuOpen ? (
              <X className="h-6 w-6" />
            ) : (
              <Menu className="h-6 w-6" />
            )}
          </button>
        </div>
      </nav>

      {isMenuOpen && (
        <div className="md:hidden border-t border-border/40">
          <div className="container py-4 space-y-4">
            <a
              href="/"
              className="flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
              onClick={() => setIsMenuOpen(false)}
            >
              <Home className="h-4 w-4" />
              Home
            </a>
            {sectionNavItems.map((item) => (
              <a
                key={item.label}
                href={item.href}
                className="block text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                {item.label}
              </a>
            ))}
            <div className="pt-2 border-t border-border/40">
              <p className="text-xs font-semibold text-muted-foreground/60 uppercase tracking-wider mb-2">
                Docs
              </p>
              {docsAudienceItems.map((item) => (
                <a
                  key={item.label}
                  href={item.href}
                  className="block py-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
                  onClick={() => setIsMenuOpen(false)}
                >
                  {item.label}
                </a>
              ))}
              <a
                href="/docs"
                className="block py-2 text-sm font-medium text-link hover:text-foreground transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                All docs →
              </a>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}

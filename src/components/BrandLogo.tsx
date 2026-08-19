interface BrandLogoProps {
    variant?: "header" | "footer";
    className?: string;
    showWordmark?: boolean;
}

export function BrandLogo({ variant = "header", className = "", showWordmark = true }: BrandLogoProps) {
    const isHeader = variant === "header";

    const iconSize = isHeader
        ? "h-9 w-9 md:h-10 md:w-10"
        : "h-10 w-10 md:h-11 md:w-11";
    const wordmarkSize = isHeader
        ? "text-xl md:text-2xl"
        : "text-xl md:text-2xl";

    return (
        <span className={`inline-flex items-center gap-2.5 shrink-0 min-w-0 ${className}`}>
            <img
                src="/img/logo/querial_icon_light.svg"
                width={26}
                height={26}
                alt=""
                className={`${iconSize} shrink-0 object-contain dark:hidden`}
            />
            <img
                src="/img/logo/querial_icon_dark.svg"
                width={26}
                height={26}
                alt=""
                className={`${iconSize} shrink-0 object-contain hidden dark:block`}
            />
            {showWordmark && (
                <span className={`${wordmarkSize} font-bold leading-none tracking-tight whitespace-nowrap`}>
                    <span className="text-foreground">Quer</span>
                    <span className="bg-gradient-to-r from-querial-indigo to-querial-indigo-on-dark bg-clip-text text-transparent">
                        ial
                    </span>
                </span>
            )}
        </span>
    );
}

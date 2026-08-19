import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, ChevronLeft, ChevronRight } from "lucide-react";

interface LightboxImage {
    src: string;
    alt: string;
    caption?: string;
}

interface LightboxProps {
    images: LightboxImage[];
    initialIndex: number;
    isOpen: boolean;
    onClose: () => void;
    /** Larger image bounds for screenshots / docs (default keeps hero-style sizing). */
    variant?: "default" | "fullscreen";
}

export function Lightbox({ images, initialIndex, isOpen, onClose, variant = "default" }: LightboxProps) {
    const [currentIndex, setCurrentIndex] = useState(initialIndex);

    useEffect(() => {
        setCurrentIndex(initialIndex);
    }, [initialIndex]);

    const nextSlide = useCallback(() => {
        setCurrentIndex((prev) => (prev + 1) % images.length);
    }, [images.length]);

    const prevSlide = useCallback(() => {
        setCurrentIndex((prev) => (prev - 1 + images.length) % images.length);
    }, [images.length]);

    useEffect(() => {
        if (!isOpen) return;
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === "Escape") onClose();
            if (e.key === "ArrowLeft") prevSlide();
            if (e.key === "ArrowRight") nextSlide();
        };
        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, [isOpen, onClose, prevSlide, nextSlide]);

    // Prevent body scroll when open
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = "hidden";
        } else {
            document.body.style.overflow = "";
        }
        return () => { document.body.style.overflow = ""; };
    }, [isOpen]);

    if (!isOpen) return null;

    const imageClassName =
        variant === "fullscreen"
            ? "max-h-[min(92vh,calc(100dvh-7rem))] max-w-[min(98vw,1600px)] w-auto rounded-2xl shadow-2xl object-contain"
            : "max-h-[70vh] max-w-[90vw] md:max-w-[60vw] rounded-2xl shadow-2xl object-contain";

    return (
        <AnimatePresence>
            {isOpen && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-black/90 backdrop-blur-sm"
                    onClick={onClose}
                >
                    {/* Close button */}
                    <button
                        onClick={onClose}
                        className="absolute top-4 right-4 p-2 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-white z-10"
                        aria-label="Close lightbox"
                    >
                        <X className="h-6 w-6" />
                    </button>

                    {/* Main image area */}
                    <div
                        className={
                            variant === "fullscreen"
                                ? "flex-1 flex items-center justify-center w-full px-4 md:px-10 py-6 min-h-0"
                                : "flex-1 flex items-center justify-center w-full px-16 py-8"
                        }
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Previous button */}
                        <button
                            onClick={prevSlide}
                            className="absolute left-4 p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-white z-10"
                            aria-label="Previous image"
                        >
                            <ChevronLeft className="h-6 w-6" />
                        </button>

                        {/* Image */}
                        <AnimatePresence mode="wait">
                            <motion.div
                                key={currentIndex}
                                initial={{ opacity: 0, scale: 0.95 }}
                                animate={{ opacity: 1, scale: 1 }}
                                exit={{ opacity: 0, scale: 0.95 }}
                                transition={{ duration: 0.2 }}
                                className="flex flex-col items-center"
                            >
                                <img
                                    src={images[currentIndex].src}
                                    alt={images[currentIndex].alt}
                                    className={imageClassName}
                                />
                                {images[currentIndex].caption && (
                                    <p className="mt-4 text-white/80 text-sm font-medium">
                                        {images[currentIndex].caption}
                                    </p>
                                )}
                            </motion.div>
                        </AnimatePresence>

                        {/* Next button */}
                        <button
                            onClick={nextSlide}
                            className="absolute right-4 p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-white z-10"
                            aria-label="Next image"
                        >
                            <ChevronRight className="h-6 w-6" />
                        </button>
                    </div>

                    {/* Thumbnail strip */}
                    <div
                        className="w-full px-4 pb-4 flex items-center justify-center gap-2 overflow-x-auto"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {images.map((image, index) => (
                            <button
                                key={index}
                                onClick={() => setCurrentIndex(index)}
                                className={`flex-shrink-0 rounded-lg overflow-hidden border-2 transition-all ${index === currentIndex
                                        ? "border-querial-sky scale-110 shadow-lg shadow-querial-sky/30"
                                        : "border-transparent opacity-50 hover:opacity-80"
                                    }`}
                                aria-label={`View ${image.caption || `image ${index + 1}`}`}
                            >
                                <img
                                    src={image.src}
                                    alt={image.alt}
                                    className="h-16 w-auto rounded-md object-cover"
                                />
                            </button>
                        ))}
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}

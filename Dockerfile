# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Build the C++ binary
# ─────────────────────────────────────────────────────────────────────────────
FROM gcc:12 AS builder

WORKDIR /build

# Copy only what is needed to compile
COPY httplib.h .
COPY main.cpp .

# Compile with optimizations; -pthread needed for std::mutex / httplib threading
RUN g++ -O2 -std=c++17 -pthread -o vectordb main.cpp

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Minimal runtime image
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

# Install runtime deps (curl needed for health checks in CI)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user — required by HuggingFace, good practice everywhere
RUN useradd -m -u 1000 user

WORKDIR /home/user/app

# Copy compiled binary and frontend
COPY --from=builder --chown=user:user /build/vectordb .
COPY --chown=user:user index.html .

USER user

# Expose all platform-relevant ports
# PORT env var will be set by hosting platform (Render=10000, HuggingFace=7860)
EXPOSE 7860 8080 10000

# PORT defaults to 7860 (Hugging Face). Render sets it to 10000 via render.yaml.
# Local Docker: override with -e PORT=8080
ENV PORT=7860
ENV OLLAMA_HOST=127.0.0.1
ENV OLLAMA_PORT=11434

CMD ["./vectordb"]

# Architecture — AI-Vector-Engine

## System Overview

The project follows the **Dual Architecture Deployment** pattern. Both models run
from the **same source code** with zero changes to application logic, UI, or features.

---

## Model 1 — Cloud-Native (Live Portfolio Link)

```mermaid
graph TB
    subgraph MODEL1["Model 1 — Cloud-Native (Render Web Service)"]
        A1[User Browser] -->|HTTPS| B1["Render Web Service\nhttps://ai-vector-engine.onrender.com"]
        B1 --> C1["C++ httplib Server\nHNSW + KD-Tree + BruteForce\nPort 10000"]
        C1 -->|"REST /api/embeddings\n/api/generate"| D1["External Ollama\n(user-provided OLLAMA_HOST)"]
        C1 --> E1["In-Memory VectorDB\n(ephemeral, resets on redeploy)"]
    end
```

**Platform:** Render Web Service (Docker runtime)
**Build:** Multi-stage Dockerfile (gcc:12 → debian:bookworm-slim)
**Port:** 10000 (set via `PORT` env var — Render requirement)
**CI/CD:** GitHub Actions → Render deploy hook on push to `main`

---

## Model 2 — Self-Hosted Docker Compose (Any Machine)

```mermaid
graph TB
    subgraph MODEL2["Model 2 — Docker Compose (localhost / VPS)"]
        A2[User Browser] -->|"Port 80"| B2["Nginx Container\nReverse Proxy"]
        B2 -->|"http://app:8080"| C2["C++ VectorDB Container\nPort 8080"]
        C2 -->|"http://ollama:11434"| D2["Ollama Container\nnomic-embed-text + llama3.2\nModels cached in Docker volume"]
        D2 --- E2[("ollama_data volume\n~4GB model weights")]
        C2 --- F2[("app_logs volume")]
    end
```

**Start command:**
```bash
docker-compose -f infra/docker/docker-compose.yml up -d
```

**Production override (resource limits + log rotation):**
```bash
docker-compose \
  -f infra/docker/docker-compose.yml \
  -f infra/docker/docker-compose.prod.yml \
  up -d
```

**Supported Environments & Platforms for Model 2:**
- **Desktop Operating Systems:** Windows 10/11 (Docker Desktop/WSL2), macOS (Intel & Apple Silicon), Linux (Ubuntu, Debian, Fedora, Arch).
- **Cloud VPS / Virtual Machines:** Any Linux server (Oracle Cloud Free Tier, DigitalOcean Droplet, Hetzner, AWS EC2, GCP Compute Engine, Linode).
- **Home Servers / Edge:** Local Homelabs, Raspberry Pi 4/5 (64-bit), Intel NUCs.
- **CI/CD Environments:** GitHub Actions runners, GitLab CI, Jenkins.


---

## Application Internals

```mermaid
graph LR
    subgraph CPP["C++ Engine (main.cpp)"]
        A["httplib::Server\nPort: $PORT"] --> B["VectorDB (16D demo)"]
        A --> C["DocumentDB (RAG, Ollama dims)"]
        B --> D["HNSW Index"]
        B --> E["KD-Tree Index"]
        B --> F["BruteForce Index"]
        C --> G["OllamaClient\n$OLLAMA_HOST:$OLLAMA_PORT"]
    end

    subgraph API["REST Endpoints"]
        H["/search"] --> A
        I["/insert + /delete"] --> A
        J["/benchmark"] --> A
        K["/hnsw-info"] --> A
        L["/doc/insert\n/doc/ask\n/doc/search"] --> A
        M["/health /ready /stats"] --> A
    end
```

---

## Port Reference

| Context | PORT | OLLAMA_HOST |
|---------|------|-------------|
| Localhost (direct) | 7860 (default) or `PORT=8080` | 127.0.0.1 |
| Docker Compose | 8080 | ollama (service name) |
| Render (cloud) | 10000 | user-provided or blank |
| Hugging Face Spaces | 7860 | user-provided |

---

## CI/CD Pipeline

```mermaid
graph LR
    A["git push main"] --> B["GitHub Actions"]
    B --> C["ci.yml\nDocker build + health check"]
    B --> D["lint.yml\ncppcheck + hadolint"]
    B --> E["test.yml\nCompile + endpoint tests"]
    B --> F["security.yml\nTrivy CVE + Gitleaks"]
    B --> G["deploy.yml\nRender deploy hook"]
    G --> H["Render rebuilds\nfrom Dockerfile"]
```

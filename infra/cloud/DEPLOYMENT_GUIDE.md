# AI-Vector-Engine — Deployment Guide (Dual Architecture)

## Architecture Summary

This project implements the **Dual Architecture Deployment Pattern**:

| Track | Model | Platform | Features |
|---|---|---|---|
| **Model 1 (Option A)** | Cloud-Native Heavy ML | **Hugging Face Spaces (Docker)** | **16GB RAM Free** — Runs C++ App + Ollama + LLMs in 1 public URL |
| **Model 1 (Option B)** | Cloud-Native Light | **Render Web Service (Docker)** | Standard Vector Search API & UI |
| **Model 2** | Self-Hosted Stack | **Docker Compose** | Full local stack (App + Ollama + Nginx) with 1 command |

---

## MODEL 1 (Option A) — Hugging Face Spaces (Full Cloud RAG + LLMs)

Hugging Face Spaces provides **16GB RAM + 2 vCPU completely free without a credit card**, allowing you to run the C++ Vector Engine AND Ollama together in a single container.

### Step 1: Create a Space
1. Go to [huggingface.co/new-space](https://huggingface.co/new-space)
2. **Space Name:** `ai-vector-engine`
3. **Select SDK:** `Docker` → `Blank`
4. **Hardware:** `Free (2 vCPU, 16GB RAM)`
5. **Visibility:** `Public`

### Step 2: Push your code
```bash
git remote add hf https://huggingface.co/spaces/YOUR_USERNAME/ai-vector-engine
git push hf main
```

### Step 3: Set Secrets / Variables
In your Space → **Settings** → **Variables and Secrets**:
- Add Variable: `PORT` = `7860`

Your app will be live at: `https://YOUR_USERNAME-ai-vector-engine.hf.space`

---

## MODEL 1 (Option B) — Render Web Service (Lightweight API)

### Step 1: Push to GitHub
```bash
git add .
git commit -m "chore: add deployment infrastructure"
git push origin main
```

### Step 2: Create a Render Web Service
1. Go to **dashboard.render.com** → **New +** → **Web Service**
2. Connect your GitHub repository
3. Settings:
   - **Name:** `ai-vector-engine` (or your choice)
   - **Language:** `Docker` ← Always Docker
   - **Branch:** `main`
   - **Region:** Oregon (US West) or closest
   - **Plan:** Free
4. **Environment Variables** → Add:
   | Key | Value |
   |-----|-------|
   | `PORT` | `10000` |
   | `OLLAMA_HOST` | *(your external Ollama host or leave blank)* |
   | `OLLAMA_PORT` | `11434` |
5. **Advanced → Health Check Path:** `/health`
6. Click **Create Web Service**
7. Live URL appears at top of dashboard after **~5 min build**

> **Note on Ollama:** Render's free tier cannot run the full Ollama LLM service
> alongside the C++ binary. The vector search / HNSW demo features work fully
> without Ollama. For RAG + Ask AI features, provide an external `OLLAMA_HOST`.

---

## MODEL 2 — Docker Compose (Self-Hosted / Local)

### Prerequisites
- Docker Desktop installed (Windows/Mac) or Docker Engine (Linux)
- At least **4GB RAM** available for Docker

### Step 1: Copy env file
```bash
cp infra/docker/.env.example infra/docker/.env
# Edit .env with your actual values
```

### Step 2: Start the full stack
```bash
docker-compose -f infra/docker/docker-compose.yml up -d
```

### Step 3: Access
| Service | URL |
|---------|-----|
| VectorDB UI | http://localhost |
| VectorDB API | http://localhost/health |
| Ollama API | http://localhost:11434 |

### Step 4: Stop
```bash
docker-compose -f infra/docker/docker-compose.yml down
```

### Step 5: View logs
```bash
docker-compose -f infra/docker/docker-compose.yml logs -f app
```

---

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `7860` | Port the C++ server listens on |
| `OLLAMA_HOST` | `127.0.0.1` | Hostname of Ollama service |
| `OLLAMA_PORT` | `11434` | Port of Ollama service |
| `SENTRY_DSN` | *(empty)* | Sentry error tracking DSN (leave blank to disable) |

---

## Localhost (No Docker)
The app continues to work exactly as before:
```bash
g++ -O2 -std=c++17 -pthread -o db main.cpp
./db
# → Server on http://localhost:7860 (or set PORT=8080 before running)
```

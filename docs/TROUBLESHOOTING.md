# Troubleshooting Guide — AI-Vector-Engine

## Common Issues

---

### ❌ "Cannot reach server — is it running on :8080?"

**Cause:** The frontend is hardcoded to `http://localhost:8080` in `index.html` (line 354: `const API = 'http://localhost:8080'`).

**Fix for production:**
When deploying, you may need to set the correct API URL. In the browser, the UI talks directly to the backend — so the backend must be publicly accessible.
- **Render:** Your backend URL will be `https://your-app-name.onrender.com`. Update `index.html` line 354 or use an environment injection script.
- **Docker Compose (localhost):** Works as-is because Nginx proxies port 80 to the C++ app on port 8080 inside the container.

---

### ❌ Docker build fails: "g++ not found"

**Cause:** The `gcc:12` base image in Stage 1 is not pulling correctly.

**Fix:**
```bash
docker pull gcc:12
docker build --no-cache -t vectordb .
```

---

### ❌ `/health` returns 404

**Cause:** The `/health` and `/ready` endpoints are served by the C++ binary. If the container isn't running, there's no server to respond.

**Fix:**
```bash
# Check if container is running
docker ps

# Check container logs
docker logs vectordb_app

# Check if the binary is listening
docker exec vectordb_app curl -s http://localhost:8080/health
```

---

### ❌ Ollama features not working (RAG / Ask AI)

**Cause:** Ollama is not running or models are not pulled.

**Fix (Docker Compose):**
```bash
# Check Ollama container is up
docker logs vectordb_ollama

# Manually pull models if the auto-pull failed
docker exec vectordb_ollama ollama pull nomic-embed-text
docker exec vectordb_ollama ollama pull llama3.2

# Verify Ollama is available
curl http://localhost:11434/api/tags
```

**Fix (Render / Cloud):** Set `OLLAMA_HOST` env var in Render dashboard to an external Ollama host. Note: Render free tier doesn't have enough RAM to run Ollama locally.

---

### ❌ Nginx returns 502 Bad Gateway

**Cause:** The `app` container is not healthy or not ready yet.

**Fix:**
```bash
# Wait for the health check to pass (can take 15-20s on first start)
docker-compose -f infra/docker/docker-compose.yml logs -f app

# Restart the stack
docker-compose -f infra/docker/docker-compose.yml restart
```

---

### ❌ Port 80 already in use

**Cause:** Another service (Apache, another Nginx) is using port 80.

**Fix:** Change the Nginx port in `docker-compose.yml`:
```yaml
nginx:
  ports:
    - "8090:80"     # Use 8090 instead of 80
```

---

### ❌ GitHub Actions CI fails: "curl: (7) Failed to connect"

**Cause:** The container takes longer than 20 seconds to start on the CI runner.

**Fix:** Increase the sleep duration in `ci.yml`:
```yaml
- name: Start container
  run: |
    docker run -d ...
    sleep 30     # Increase from 20 to 30
```

---

### ❌ Render deploy hook not triggering

**Cause:** `RENDER_DEPLOY_HOOK_URL` secret is not set in GitHub repository settings.

**Fix:**
1. Go to Render dashboard → your service → **Settings** → **Deploy Hook**
2. Copy the URL
3. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
4. Add secret: `RENDER_DEPLOY_HOOK_URL` = `<copied URL>`

---

## Common Mistakes (from the UDADP v3.0)

| ❌ Wrong | ✅ Right |
|---|---|
| Hardcode `localhost:8080` in frontend | Use env var or relative URL |
| Deploy without `/health` endpoint | Always add it — Render requires it |
| Run Docker container as root | `useradd -m -u 1000 user` in Dockerfile ✅ done |
| Commit `.env` to GitHub | Only commit `.env.example` |
| Skip CI/CD | All 5 workflows are in `.github/workflows/` |

---

## Localhost Quick Start (No Docker)

```bash
# Windows (from project root)
g++ -O2 -std=c++17 -o db main.cpp
./db

# Linux/Mac
g++ -O2 -std=c++17 -pthread -o db main.cpp
PORT=8080 ./db
```

Open `http://localhost:8080` (or whatever PORT you set).

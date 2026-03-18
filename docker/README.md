# NexusAgent Docker Configuration

## Quick Start

```bash
# Build the image
docker build -t nexusagent/server .

# Run with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f nexusagent

# Stop
docker-compose down
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NEXUSAGENT_JWT_SECRET` | Yes | - | JWT signing secret |
| `NEXUSAGENT_PORT` | No | 3000 | Server port |
| `NEXUSAGENT_DB_URL` | No | - | PostgreSQL connection string |
| `NEXUSAGENT_LOG_LEVEL` | No | info | Log level (debug, info, warn, error) |

## Volumes

| Path | Description |
|------|-------------|
| `/app/config.json` | Configuration file |
| `/app/data` | Application data |
| `/var/log/nexusagent` | Log files |

## Ports

| Port | Description |
|------|-------------|
| 3000 | Main API server |

## Examples

### With Custom Config

```bash
docker run -d \
  -p 3000:3000 \
  -v $(pwd)/config.json:/app/config.json:ro \
  -e NEXUSAGENT_JWT_SECRET=my-secret \
  nexusagent/server
```

### With PostgreSQL

```bash
docker run -d \
  -p 3000:3000 \
  -e NEXUSAGENT_JWT_SECRET=my-secret \
  -e NEXUSAGENT_DB_URL=postgresql://user:pass@db:5432/nexusagent \
  --link nexusagent-db:db \
  nexusagent/server
```

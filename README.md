# NexusAgent 🤖

**Enterprise-grade AI Agent Platform** - Secure, scalable alternative to OpenClaw with 10x security improvements.

## Features

- 🔐 **Session Isolation** - Per-user authentication
- 🛡️ **Security Hardening** - Filesystem sandbox, tool policies, rate limiting
- 📱 **Multi-channel** - Telegram, Discord, Slack, WhatsApp, Signal & more
- 🧠 **Smart Memory** - Semantic search with vector embeddings
- 📊 **Real-time Dashboard** - Live agent monitoring
- 🔄 **WebSocket Support** - Real-time updates
- ⏰ **Cron Jobs** - Automated scheduling
- 📈 **Analytics** - Usage metrics & performance tracking

## Tech Stack

- **Backend:** Dart/Node.js
- **Frontend:** Flutter (Mobile), React (Web)
- **Database:** PostgreSQL + pgvector
- **Cache:** Redis
- **Sandbox:** Docker + gVisor

## Quick Start

```bash
# Clone the repo
git clone https://github.com/shubhamrathodsidehusle1-arch/nexusagent.git
cd nexusagent

# Install dependencies
cd server && npm install
cd ../app && flutter pub get

# Run
cd server && npm start
```

## Configuration

Set environment variables:
```bash
NEXUSAGENT_JWT_SECRET=your-secret-key
NEXUSAGENT_PORT=3000
NEXUSAGENT_DB_URL=postgresql://localhost:5432/nexusagent
```

## Security

NexusAgent includes comprehensive security features:
- Input validation & prompt injection blocking
- Path traversal protection
- SSRF protection for web fetching
- Shell injection prevention
- Audit logging
- RBAC + SSO support

## License

MIT License

## Support

- Discord: https://discord.gg/nexusagent
- Email: support@nexusagent.io

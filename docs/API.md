# NexusAgent API Documentation

**Version:** 1.0.0

Welcome to the NexusAgent API. This documentation covers all endpoints and their usage.

---

## Authentication

### Register

Register a new user account.

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

### Login

Login with email and password.

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Login with SSO

Login using SSO provider.

```http
GET /api/auth/sso/{provider}
```

**Providers:** `google`, `microsoft`, `github`, `slack`

**Response:**
Redirects to provider OAuth flow.

### Me

Get current user info.

```http
GET /api/auth/me
Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "owner",
  "workspaceId": "ws_456"
}
```

---

## Agents

### List Agents

Get all agents.

```http
GET /api/agents
Authorization: Bearer {token}
```

**Response:**
```json
{
  "agents": [
    {
      "id": "agent_123",
      "name": "Support Bot",
      "description": "Handles support requests",
      "status": "active",
      "tools": ["web_search", "memory"],
      "createdAt": "2026-01-15T10:00:00Z"
    }
  ]
}
```

### Create Agent

Create a new agent.

```http
POST /api/agents
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "New Agent",
  "description": "Agent description",
  "model": "openai/gpt-4",
  "tools": ["web_search", "web_fetch", "memory"]
}
```

### Get Agent

Get agent by ID.

```http
GET /api/agents/{agentId}
Authorization: Bearer {token}
```

### Update Agent

Update agent.

```http
PUT /api/agents/{agentId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Updated Name",
  "tools": ["web_search", "memory", "message"]
}
```

### Delete Agent

Delete agent.

```http
DELETE /api/agents/{agentId}
Authorization: Bearer {token}
```

### Run Agent

Execute agent with input.

```http
POST /api/agents/{agentId}/run
Authorization: Bearer {token}
Content-Type: application/json

{
  "input": "Hello, agent!",
  "sessionId": "session_789"
}
```

**Response:**
```json
{
  "runId": "run_456",
  "status": "ok",
  "output": "Hello! How can I help you?",
  "tokensUsed": 150,
  "steps": [
    {"order": 1, "action": "validate_input", "success": true},
    {"order": 2, "action": "web_search", "result": "...", "success": true}
  ]
}
```

---

## Tools

### List Tools

Get available tools.

```http
GET /api/tools
Authorization: Bearer {token}
```

**Response:**
```json
{
  "tools": [
    {
      "name": "web_search",
      "description": "Search the web",
      "category": "data",
      "requiresApproval": false
    },
    {
      "name": "exec",
      "description": "Execute commands",
      "category": "execution",
      "requiresApproval": true
    }
  ]
}
```

### Execute Tool

Execute a tool directly.

```http
POST /api/tools/execute
Authorization: Bearer {token}
Content-Type: application/json

{
  "toolName": "web_search",
  "params": {
    "query": "latest news"
  }
}
```

---

## Skills

### List Skills

Get installed skills.

```http
GET /api/skills
Authorization: Bearer {token}
```

### Install Skill

Install a new skill.

```http
POST /api/skills
Authorization: Bearer {token}
Content-Type: application/json

{
  "source": "https://github.com/nexusagent/skill-github"
}
```

---

## Workflows

### List Workflows

Get all workflows.

```http
GET /api/workflows
Authorization: Bearer {token}
```

### Create Workflow

Create a new workflow.

```http
POST /api/workflows
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "New Workflow",
  "description": "Automate tasks",
  "nodes": [
    {"id": "1", "type": "trigger", "config": {"channel": "telegram"}},
    {"id": "2", "type": "agent", "config": {"agentId": "agent_123"}},
    {"id": "3", "type": "action", "config": {"action": "send"}}
  ]
}
```

### Run Workflow

Execute a workflow.

```http
POST /api/workflows/{workflowId}/run
Authorization: Bearer {token}
```

---

## Cron Jobs

### List Jobs

Get scheduled jobs.

```http
GET /api/cron
Authorization: Bearer {token}
```

### Create Job

Create a scheduled job.

```http
POST /api/cron
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Daily Report",
  "schedule": "0 9 * * *",
  "task": "Send report",
  "params": {"agentId": "agent_123"}
}
```

### Delete Job

Delete a job.

```http
DELETE /api/cron/{jobId}
Authorization: Bearer {token}
```

---

## Sessions

### List Sessions

Get active sessions.

```http
GET /api/sessions
Authorization: Bearer {token}
```

### Get Session

Get session details.

```http
GET /api/sessions/{sessionId}
Authorization: Bearer {token}
```

### End Session

End a session.

```http
DELETE /api/sessions/{sessionId}
Authorization: Bearer {token}
```

---

## Channels

### List Channels

Get configured channels.

```http
GET /api/channels
Authorization: Bearer {token}
```

### Enable Channel

Enable a channel.

```http
POST /api/channels/{channelId}/enable
Authorization: Bearer {token}
```

### Disable Channel

Disable a channel.

```http
POST /api/channels/{channelId}/disable
Authorization: Bearer {token}
```

---

## Analytics

### Get Analytics

Get analytics data.

```http
GET /api/analytics
Authorization: Bearer {token}
Query Parameters:
  - startDate: ISO date
  - endDate: ISO date
  - agentId: filter by agent
```

**Response:**
```json
{
  "totalAgents": 12,
  "activeSessions": 23,
  "messagesToday": 1247,
  "successRate": 98.7,
  "messagesByChannel": {
    "telegram": 34567,
    "discord": 28432
  }
}
```

---

## Teams

### List Members

Get team members.

```http
GET /api/team/members
Authorization: Bearer {token}
```

### Invite Member

Invite a team member.

```http
POST /api/team/invite
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": "colleague@example.com",
  "role": "member"
}
```

### Update Role

Update member role.

```http
PUT /api/team/members/{memberId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "role": "admin"
}
```

### Remove Member

Remove team member.

```http
DELETE /api/team/members/{memberId}
Authorization: Bearer {token}
```

---

## Webhooks

### Register Webhook

Register a webhook URL.

```http
POST /api/webhooks
Authorization: Bearer {token}
Content-Type: application/json

{
  "url": "https://your-server.com/webhook",
  "events": ["agent.run.complete", "session.start"]
}
```

### Delete Webhook

Delete a webhook.

```http
DELETE /api/webhooks/{webhookId}
Authorization: Bearer {token}
```

---

## Errors

All errors return standard HTTP status codes:

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 429 | Rate Limited - Too many requests |
| 500 | Server Error - Something went wrong |

**Error Response:**
```json
{
  "error": "Invalid parameters",
  "message": "Email is required"
}
```

---

## Rate Limits

API requests are rate limited:

- **Authenticated:** 100 requests/minute
- **Unauthenticated:** 20 requests/minute

Rate limit headers are included in responses:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

---

## SDKs

Official SDKs available:

- **Python:** `pip install nexusagent`
- **JavaScript:** `npm install nexusagent`
- **Dart:** `dart add nexusagent`

### Python Example

```python
import nexusagent

client = nexusagent.Client(api_key="your-api-key")

# Run agent
result = client.agents.run("agent_123", "Hello!")
print(result.output)
```

### JavaScript Example

```javascript
import { NexusAgent } from 'nexusagent';

const client = new NexusAgent({ apiKey: 'your-api-key' });

// Run agent
const result = await client.agents.run('agent_123', 'Hello!');
console.log(result.output);
```

---

## Support

- Discord: https://discord.gg/nexusagent
- GitHub: https://github.com/nexusagent
- Email: support@nexusagent.io

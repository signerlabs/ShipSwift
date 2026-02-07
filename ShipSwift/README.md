# ShipSwift

AI-native development reference library for iOS — let AI build production-quality apps with battle-tested recipes.

## Vision

ShipSwift is not a boilerplate you copy-paste. It's a **structured knowledge base** designed for LLMs (Claude, GPT, etc.) to reference when building iOS apps. When a solo developer says "help me add subscriptions", the AI gets production-grade context — architecture decisions, complete implementation, and known pitfalls — instead of generating incomplete code from generic training data.

## Product

### Core: Recipe-based MCP Server

Each feature is organized as a self-contained **Recipe** — a complete implementation guide optimized for AI consumption.

```
shipswift-mcp/
├── src/
│   ├── server.ts              # MCP Server entry
│   ├── tools/
│   │   ├── listRecipes.ts     # List available recipes
│   │   ├── getRecipe.ts       # Get full recipe content
│   │   └── searchRecipes.ts   # Search by keyword
│   └── license.ts             # Local license validation
├── recipes/
│   ├── free/                  # Free recipes (shipped with repo)
│   │   ├── ui-components/
│   │   ├── animations/
│   │   └── onboarding/
│   └── pro/                   # Paid recipes (encrypted, unlocked by license key)
│       ├── auth-cognito/
│       ├── subscription-storekit/
│       ├── ai-chat-streaming/
│       ├── voice-input-asr/
│       ├── infra-cdk/
│       └── database-aurora/
└── package.json
```

### Recipe Format

Every recipe follows a fixed structure for consistent AI parsing:

```markdown
---
id: auth-cognito
requires: []
pairs_with: [subscription-storekit, ai-chat-streaming]
platform: ios + aws
complexity: medium
---

# Recipe Title

## What This Solves
[One sentence]

## Architecture Decisions
[Why this approach, trade-offs vs alternatives]

## Dependencies
[Exact versions]

## Implementation
### iOS
[Complete Swift code with inline comments on key decisions]

### Backend
[CDK definitions + Lambda handlers]

## Integration Checklist
- [ ] Step 1: ...
- [ ] Step 2: ...

## Common Customizations
- Want Google Sign-In? → Modify here
- Want OTP login? → See variants/otp.md

## Known Pitfalls
[Real-world bugs and edge cases from production apps]
```

Key design choices:
- AI reads one `recipe.md` and has full context — no cross-file hunting
- `pairs_with` tells AI which modules work together
- `Common Customizations` lets AI handle user-specific requests
- `Known Pitfalls` is the core moat — real-world experience you can't find on Stack Overflow

## Distribution Channels

Same recipe content, adapted for different AI tools:

| Channel | Format | Use Case |
|---------|--------|----------|
| **GitHub repo** | Raw files | Claude Code / Cursor reads local files |
| **MCP Server** | On-demand retrieval | Fetch only the relevant recipe, saves context window |
| **Claude Project** | Uploaded to Project Knowledge | "Build me an app based on ShipSwift" |
| **Docs website** | Rendered for humans | Developers browse and learn |

MCP Server is the primary distribution — users install it in Claude Code, and when they say "add subscription", the MCP automatically feeds the right recipe to the AI.

## Business Model: Open-core + One-time Purchase

### Pricing

| Tier | Price | Content |
|------|-------|---------|
| **Free** | $0 | MCP Server + 3-4 free recipes |
| **Pro** | $79 one-time | All recipes (current + updates in this major version) |
| **Upgrade** | $29 per major version | Future major recipe packs |

### Why This Model

1. **Open-source MCP Server is the growth engine**
   - GitHub stars and forks = free distribution
   - Early mover in MCP ecosystem (Anthropic is building an MCP directory)
   - Developers trust open-source tools

2. **Free recipes build trust**
   - Users experience the quality difference: "AI with ShipSwift context writes dramatically better code"
   - This aha moment is the conversion point

3. **One-time purchase fits the target user**
   - Solo developers hate subscriptions for tools they don't use daily
   - $79 for saving days of development time is a no-brainer
   - No subscription fatigue, no churn problem

4. **Upgrade pricing creates sustainable revenue**
   - New recipe packs (CloudKit, Push Notifications, Widgets, etc.)
   - Existing users pay $29, new users still pay $79 for everything
   - Not a subscription, but has recurring revenue potential

### Free vs Pro Content

**Free recipes** (demonstrate value):
- UI Components (slComponent collection)
- Animations (slAnimation collection)
- Onboarding flow

**Pro recipes** (solve painful problems every app needs):
- Auth system (Cognito + Amplify)
- Subscription system (StoreKit 2 + server validation)
- AI streaming chat (Lambda Response Streaming + SSE)
- Voice input (VolcEngine ASR)
- Infrastructure (AWS CDK full stack)
- Database (Aurora Serverless + Drizzle ORM)
- Messaging (SES/SNS + Aliyun SMS)

### Content Protection

Pro recipes use **local encryption** (not a remote API):
- Encrypted recipe files ship with the repo
- License key decrypts locally — no server dependency
- Solo developers prefer tools that work offline

## User Journey

```
Discovery → Trial → Conversion → Retention

1. DISCOVER on GitHub / Twitter / MCP directory
2. INSTALL free MCP Server, try with Claude Code
   "Help me build an onboarding page" → AI calls ShipSwift → perfect output
3. CONVERT when hitting a paid recipe
   "Add subscription" → MCP returns: "This is a Pro recipe. Purchase to unlock."
4. PAY $79, unlock everything locally
5. RETAIN with future recipe pack upgrades ($29)
```

## Current Recipe Inventory (from existing codebase)

| Recipe | Source | iOS | Backend | Completeness |
|--------|--------|-----|---------|-------------|
| Auth (Cognito) | slUserManager + 1_auth.md | ✅ | ✅ | High |
| Subscription (StoreKit 2) | slStoreManager + 3_subscription.md | ✅ | ✅ | High |
| AI Streaming Chat | slChat + 7_streaming.md | ✅ | Partial | Medium |
| Voice Input (ASR) | slChat/ASR + 6_asr.md | ✅ | ✅ | High |
| Paywall UI | slPaywallView | ✅ | — | Medium |
| Onboarding | slOnboardingView | ✅ | — | Medium |
| Infrastructure (CDK) | 0_cdk.md | — | ✅ | High |
| Database (Aurora) | 2_database.md | — | ✅ | High |
| Messaging | 5_messaging.md | — | ✅ | High |
| Lambda | 4_lambda.md | — | ✅ | High |

**MVP scope: 3-4 free + 6-7 pro recipes, enough to validate the full pipeline.**

## Tech Stack

### Existing (iOS app templates)

- SwiftUI + Swift
- StoreKit 2 (In-app purchases)
- Amplify SDK (AWS integration)
- SpriteKit (animations)
- VolcEngine (ASR)

### Backend (covered in docs)

- AWS CDK (Infrastructure as Code)
- AWS Cognito (Authentication)
- Aurora Serverless v2 (Database)
- Lambda (Serverless functions)
- App Runner + Hono (API server)
- Drizzle ORM (Database operations)

### MCP Server (to build)

- TypeScript
- MCP SDK (@modelcontextprotocol/sdk)
- Local license validation (no server dependency)

## Design Principles

1. **AI-first** — content structured for LLM consumption, not just human reading
2. **Battle-tested** — every recipe comes from production apps (Fullpack, Truvet, etc.)
3. **Self-contained** — one recipe = complete context, no cross-file dependencies
4. **Offline-first** — everything works locally, no external service required
5. **Full-stack** — iOS + backend in each recipe, because solo developers ship both

## Roadmap

### Phase 1: MVP
- [ ] Restructure existing content into recipe format
- [ ] Build MCP Server with free/pro gating
- [ ] Implement local license validation
- [ ] Ship 3 free + 6 pro recipes
- [ ] Open-source the MCP Server on GitHub

### Phase 2: Launch
- [ ] Landing page / docs website
- [ ] Payment integration (Gumroad / LemonSqueezy)
- [ ] Submit to MCP directories
- [ ] Twitter / indie hacker community launch

### Phase 3: Expand
- [ ] New recipe packs (CloudKit, Push Notifications, Widgets, SwiftData)
- [ ] Claude Project pre-configured template
- [ ] Video walkthroughs for human learners
- [ ] Community recipe contributions

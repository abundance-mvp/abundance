# Abundance Backend (Firebase Cloud Functions)

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

**Local Development:**

```bash
cp .env.example .env
# Edit .env and add your GOOGLE_API_KEY
```

Get API key: https://aistudio.google.com/app/apikey

**Cloud Functions (Production):**

```bash
firebase functions:config:set gemini.api_key="YOUR_API_KEY"
```

### 3. Run Tests

```bash
npm test
```

### 4. Build

```bash
npm run build
```

### 5. Deploy

```bash
firebase deploy --only functions
```

## Architecture

- **Layer 2a**: Gemini attribute extraction (category, color, material, condition)
- **Cost Tracking**: All API calls logged to Firestore `costLogs` collection
- **Retry Logic**: Exponential backoff for transient errors

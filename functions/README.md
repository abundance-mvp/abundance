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

## Storage Upload Processing

Firebase Storage uploads include processing metadata that can trigger Cloud Functions:

### Upload Metadata

The iOS app adds the following custom metadata to all uploads:

```json
{
  "uploadedAt": "2024-01-15T12:00:00Z",
  "itemId": "abc123",
  "userId": "user456",
  "processingStatus": "pending",
  "uploadSource": "camera-detection"
}
```

| Field | Description |
|-------|-------------|
| `processingStatus` | `pending` \| `processing` \| `complete` \| `failed` |
| `uploadSource` | `camera-detection` \| `live-photo-capture` \| `manual-upload` |

### Storage Trigger Pattern

To create a Cloud Function that triggers on Storage uploads:

```typescript
import { onObjectFinalized } from 'firebase-functions/v2/storage';

export const onImageUploaded = onObjectFinalized(
  { bucket: 'your-project.appspot.com' },
  async (event) => {
    const { name, contentType, metadata } = event.data;

    // Filter for pending items from camera detection
    if (metadata?.processingStatus !== 'pending') return;
    if (metadata?.uploadSource !== 'camera-detection') return;

    const { itemId, userId } = metadata;

    // Process the image...
    // Update metadata when complete:
    // await storage.bucket().file(name).setMetadata({
    //   metadata: { processingStatus: 'complete' }
    // });
  }
);
```

### Current Processing Flow

1. **iOS App** uploads cropped image to `users/{userId}/items/{itemId}.jpg`
2. **iOS App** creates Firestore document with `imageUrl`
3. **onItemCreated** Firestore trigger initiates Layer 2a processing
4. **Gemini** extracts attributes (category, color, material, condition)

### Alternative: Storage-First Processing

For workflows that need to process images before creating Firestore documents:

1. **iOS App** uploads to Storage with `processingStatus: "pending"`
2. **onImageUploaded** Storage trigger processes the image
3. **Cloud Function** creates Firestore document after processing
4. **Cloud Function** updates Storage metadata to `processingStatus: "complete"`

This pattern is useful for:
- Image validation before database writes
- Background image optimization
- Pre-processing with Cloud Vision API
- Async workflows that don't need immediate Firestore documents

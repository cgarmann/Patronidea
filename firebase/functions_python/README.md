# Deprecated Smart Engine Tooling

This folder is not part of the production Firebase deployment.

The production Smart Engine is `firebase/functions/index.js` and uses:

- OpenAI `text-embedding-3-small`
- Pinecone nearest-neighbor search
- `publicIdeas` projection writes from the Node function

Keep this Python/S-BERT code only for offline threshold experiments,
backfills, and clustering research. Do not add it to `firebase.json` unless
the production architecture is intentionally changed.

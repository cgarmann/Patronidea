"""
Smart Engine — Python Cloud Function
Bruker S-BERT (all-MiniLM-L6-v2) og cosine similarity for semantisk deduplisering.

Terskler (fra din Streamlit-prototype):
  score > 0.80  → rejected      (duplikat)
  score > 0.60  → needs_review  (ligner på noe)
  score <= 0.60 → active        (unik)
"""

from firebase_functions import firestore_fn, options
from firebase_admin import initialize_app, firestore as admin_firestore
import numpy as np
from sentence_transformers import SentenceTransformer
import logging

initialize_app()
logger = logging.getLogger(__name__)

# ── Modell caches mellom Cloud Function-instanser (warm starts) ──────────────
_model: SentenceTransformer | None = None


def _get_model() -> SentenceTransformer:
    global _model
    if _model is None:
        logger.info("Laster S-BERT modell (all-MiniLM-L6-v2)...")
        _model = SentenceTransformer("all-MiniLM-L6-v2")
    return _model


def _cosine_similarity(vec_a: np.ndarray, matrix: np.ndarray) -> np.ndarray:
    """Beregner cosine similarity mellom én vektor og en matrise av vektorer."""
    norm_a = np.linalg.norm(vec_a)
    norms = np.linalg.norm(matrix, axis=1)
    # Unngå divisjon med null
    safe_norms = np.where(norms == 0, 1e-9, norms)
    return np.dot(matrix, vec_a) / (safe_norms * norm_a)


# ── Cloud Function ────────────────────────────────────────────────────────────

@firestore_fn.on_document_created(
    document="ideas/{ideaId}",
    memory=options.MemoryOption.GB_2,   # Nødvendig for å laste BERT-modellen
    timeout_sec=300,
    region="us-central1",
)
def analyze_idea(
    event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None],
) -> None:
    """
    Kjøres automatisk når en ny idé legges til i Firestore.
    Sammenligner idéen semantisk med alle eksisterende, oppdaterer status.
    """
    snapshot = event.data
    if snapshot is None:
        return

    idea = snapshot.to_dict()
    idea_id = event.params["ideaId"]
    db = admin_firestore.client()
    idea_ref = db.collection("ideas").document(idea_id)

    # Kjør bare på nye, ubehandlede idéer
    if idea.get("status") != "processing":
        return

    title = idea.get("title", "")
    body = idea.get("body", "")
    full_text = f"{title}. {body}"

    try:
        model = _get_model()

        # ── Steg 1: Generer embedding for den nye idéen ──────────────────────
        new_vec = model.encode(full_text, normalize_embeddings=True)

        # ── Steg 2: Hent alle eksisterende embeddings fra Firestore ──────────
        embeddings_snap = (
            db.collection("embeddings")
            .where("status", "in", ["active", "needs_review"])
            .get()
        )

        if not embeddings_snap:
            # Første idé i databasen — alltid unik
            _save_result(
                db=db,
                idea_ref=idea_ref,
                idea_id=idea_id,
                new_vec=new_vec,
                status="active",
                match_score=0.0,
                matched_idea_id=None,
                matched_idea_title=None,
            )
            return

        # ── Steg 3: Beregn cosine similarity mot alle eksisterende ───────────
        existing_ids = []
        existing_vecs = []
        existing_titles = []

        for doc in embeddings_snap:
            d = doc.to_dict()
            vec_list = d.get("embedding")
            if vec_list is None:
                continue
            existing_ids.append(doc.id)
            existing_vecs.append(np.array(vec_list, dtype=np.float32))
            existing_titles.append(d.get("title", ""))

        vec_matrix = np.stack(existing_vecs)  # shape: (N, 384)
        similarities = _cosine_similarity(new_vec, vec_matrix)

        max_score = float(np.max(similarities))
        best_idx = int(np.argmax(similarities))
        matched_id = existing_ids[best_idx]
        matched_title = existing_titles[best_idx]

        logger.info(f"Idé {idea_id}: max_similarity={max_score:.4f} mot {matched_id}")

        # ── Steg 4: Bestem status basert på terskler ─────────────────────────
        if max_score > 0.80:
            status = "rejected"
        elif max_score > 0.60:
            status = "needs_review"
            matched_id = matched_id      # behold referansen
        else:
            status = "active"
            matched_id = None
            matched_title = None

        # ── Steg 5: Lagre resultat ────────────────────────────────────────────
        _save_result(
            db=db,
            idea_ref=idea_ref,
            idea_id=idea_id,
            new_vec=new_vec,
            status=status,
            match_score=max_score,
            matched_idea_id=matched_id if status != "active" else None,
            matched_idea_title=matched_title if status != "active" else None,
        )

    except Exception as exc:
        logger.exception(f"Smart Engine feilet for idé {idea_id}: {exc}")
        idea_ref.update({
            "status": "error",
            "updatedAt": admin_firestore.SERVER_TIMESTAMP,
        })


def _save_result(
    db,
    idea_ref,
    idea_id: str,
    new_vec: np.ndarray,
    status: str,
    match_score: float,
    matched_idea_id: str | None,
    matched_idea_title: str | None,
) -> None:
    """Oppdaterer idé-dokumentet og lagrer embedding for fremtidige sammenligninger."""

    uniqueness_score = round((1.0 - match_score) * 100)

    batch = db.batch()

    # Oppdater idé-dokumentet
    update_data: dict = {
        "status": status,
        "uniquenessScore": uniqueness_score,
        "matchScore": round(match_score, 4),
        "updatedAt": admin_firestore.SERVER_TIMESTAMP,
    }
    if matched_idea_id:
        update_data["matchedIdeaId"] = matched_idea_id
        update_data["matchedIdeaTitle"] = matched_idea_title

    batch.update(idea_ref, update_data)

    # Lagre embedding (kun for aktive/needs_review — ikke for duplikater)
    if status in ("active", "needs_review"):
        idea_data = idea_ref.get().to_dict() or {}
        emb_ref = db.collection("embeddings").document(idea_id)
        batch.set(emb_ref, {
            "embedding": new_vec.tolist(),   # list[float] — Firestore støtter ikke ndarray direkte
            "ideaId": idea_id,
            "title": idea_data.get("title", ""),
            "status": status,
            "createdAt": admin_firestore.SERVER_TIMESTAMP,
        })

    batch.commit()
    logger.info(f"Idé {idea_id} → status={status}, uniqueness={uniqueness_score}%")

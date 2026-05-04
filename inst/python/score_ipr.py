"""DeBERTa-v3 hypothesis-alignment scoring for NTE IPR paragraphs.

Replicates the inference pipeline used in the fine-tuning notebook
(NTE_DeBERTa_V3_revised_colab.ipynb). For each input paragraph the
model evaluates 13 hand-crafted hypotheses about IPR barriers, takes
the softmax probability of entailment for each, multiplies by a fixed
hypothesis weight, and sums to produce a raw score. The raw score is
then min-max rescaled to roughly [-5, +5] using the bounds of the
published 1,432-paragraph corpus, so new scores are on the same scale
as the bundled NTE_IPR_scored dataset.

Imported from R via reticulate. Exposes a single `score()` function
that takes parallel lists of texts, countries, and years.
"""

import torch
from transformers import AutoModelForSequenceClassification, AutoTokenizer


_MODEL_CACHE = {}


HYPOTHESES = [
    {"id": "H1",  "text": "The country is the Priority Foreign Country.", "weight": -2.0},
    {"id": "H2",  "text": "The country is on the Priority Watch List.", "weight": -2.0},
    {"id": "H3",  "text": "The country is on the Watch List.", "weight": -1.5},
    {"id": "H4",  "text": "The country has markets listed as the Notorious Market.", "weight": -1.5},
    {"id": "H5",  "text": "The author of this text believes that the country does not put in efforts to combat IPR violations.", "weight": -1.0},
    {"id": "H6",  "text": "The author of this text believes that the country has made efforts to combat IPR violations.", "weight":  1.0},
    {"id": "H7",  "text": "The author of this text supports the passage of the new IPR legislation in the country.", "weight":  1.0},
    {"id": "H8",  "text": "The author of this text opposes the passage of the new IPR legislation in the country.", "weight": -1.0},
    {"id": "H9",  "text": "The author of this text believes that there is widespread IPR violation in the country.", "weight": -1.5},
    {"id": "H10", "text": "The author of this text believes that the country is lack of resources to combat IPR violations.", "weight": -1.0},
    {"id": "H11", "text": "The author of this text believes that the country has strong IPR law.", "weight":  2.0},
    {"id": "H12", "text": "This text mentions the increase of IPR violations in the country.", "weight": -1.0},
    {"id": "H13", "text": "This text mentions the decrease of IPR violations in the country.", "weight":  1.0},
]


# Min-max bounds from the published 1,432-paragraph corpus run.
# Source: NTE_DeBERTa_V3_revised_colab.ipynb, cell 12.
PUBLISHED_RAW_MIN = -8.7824
PUBLISHED_RAW_MAX =  4.5083


def _resolve_device(device):
    if device is not None:
        return device
    if torch.cuda.is_available():
        return "cuda"
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def _get_model(model_id, device):
    cache_key = (model_id, device)
    if cache_key in _MODEL_CACHE:
        return _MODEL_CACHE[cache_key]
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    model = AutoModelForSequenceClassification.from_pretrained(
        model_id, attn_implementation="eager"
    )
    model = model.float().to(device)
    model.eval()
    _MODEL_CACHE[cache_key] = (tokenizer, model)
    return tokenizer, model


def _make_premise(text, country, year):
    return (
        f"This text is about the IPR protection situation in country "
        f"{country} and year {year}: {text}"
    )


def score(text, country, year,
          model_id="jacqpark/nte-deberta-ipr",
          batch_size=32, device=None,
          rescale=True):
    """Score paragraphs and return one score per input."""
    device = _resolve_device(device)
    tokenizer, model = _get_model(model_id, device)

    if isinstance(text, str):
        text = [text]
    if isinstance(country, str):
        country = [country]
    try:
        year = list(year)
    except TypeError:
        year = [year]
    text = [str(t) for t in text]
    country = [str(c) for c in country]
    year = [int(y) for y in year]

    n_obs = len(text)
    if not (len(country) == n_obs == len(year)):
        raise ValueError("text, country, and year must all be the same length.")

    all_premises, all_hyps, all_weights, obs_idx = [], [], [], []
    for i, (t, c, y) in enumerate(zip(text, country, year)):
        premise = _make_premise(t, c, y)
        for h in HYPOTHESES:
            all_premises.append(premise)
            all_hyps.append(h["text"])
            all_weights.append(h["weight"])
            obs_idx.append(i)

    entail_probs = []
    for start in range(0, len(all_premises), batch_size):
        end = min(start + batch_size, len(all_premises))
        enc = tokenizer(
            all_premises[start:end],
            all_hyps[start:end],
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="pt",
        ).to(device)
        with torch.no_grad():
            logits = model(**enc).logits
        probs = torch.softmax(logits, dim=-1)
        entail_probs.extend(probs[:, 0].detach().cpu().tolist())

    raw = [0.0] * n_obs
    for prob, w, oi in zip(entail_probs, all_weights, obs_idx):
        raw[oi] += prob * w

    if not rescale:
        return raw

    span = PUBLISHED_RAW_MAX - PUBLISHED_RAW_MIN
    return [-5.0 + 10.0 * (r - PUBLISHED_RAW_MIN) / span for r in raw]

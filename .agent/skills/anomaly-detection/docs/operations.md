# Operations and Compliance Notes

## Audit Trail

Each batch should save:

- input snapshot hash
- schema version
- config hash
- model version
- execution timestamp
- user/service account
- output hash
- reviewer decision when available

## 21 CFR Part 11 Considerations

This scaffold is not a validated Part 11 system. For regulated production use, connect it to validated identity, access control, audit trail, electronic signature, change control, backup, and SOP-governed operational processes.

## Privacy

- Avoid PHI/PII in logs.
- Prefer surrogate `record_id`.
- Subject identifiers should be pseudonymized upstream.
- Store model inputs only when justified by audit/reproducibility requirements.

## Deployment

Local:

```bash
uvicorn anomaly_detection.api:app --reload
```

Docker:

```bash
docker build -f deploy/Dockerfile -t edc-rwd-anomaly-detection:0.1.0 .
docker run -p 8000:8000 edc-rwd-anomaly-detection:0.1.0
```

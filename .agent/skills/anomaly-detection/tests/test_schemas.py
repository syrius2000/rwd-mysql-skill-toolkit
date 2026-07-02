from anomaly_detection.schemas import DetectionRequest


def test_detection_request_schema():
    req = DetectionRequest(
        study_id="S",
        records=[{"record_id": "r1", "values": {"age": 60}, "metadata": {"source": "EDC"}}],
    )
    assert req.records[0].record_id == "r1"

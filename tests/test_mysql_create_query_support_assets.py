from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = "mysql-create-query-support"
REQUIRED_RELATIVE_FILES = [
    "SKILL.md",
    "templates/query_note.md",
    "templates/main_query.sql",
    "templates/validation_query.sql",
    "references/query_design_checklist.md",
]


def test_query_support_skill_exists_in_agent_and_cursor():
    for base in [".agent/skills", ".cursor/skills"]:
        for rel in REQUIRED_RELATIVE_FILES:
            path = ROOT / base / SKILL / rel
            assert path.exists(), f"missing {path}"


def test_agent_and_cursor_query_support_files_match():
    for rel in REQUIRED_RELATIVE_FILES:
        agent_file = ROOT / ".agent/skills" / SKILL / rel
        cursor_file = ROOT / ".cursor/skills" / SKILL / rel
        assert agent_file.read_text(encoding="utf-8") == cursor_file.read_text(encoding="utf-8")


def test_query_support_skill_requires_validation_sql_and_note():
    skill_md = (ROOT / ".agent/skills" / SKILL / "SKILL.md").read_text(encoding="utf-8")
    assert "main_query.sql" in skill_md
    assert "validation_query.sql" in skill_md
    assert "query_note.md" in skill_md
    assert "粒度" in skill_md
    assert "COUNT(DISTINCT" in skill_md


def test_root_sql_asset_directories_exist():
    for rel in ["sql/README.md", "sql/drafts/.gitkeep", "sql/validated/.gitkeep", "sql/examples/.gitkeep"]:
        path = ROOT / rel
        assert path.exists(), f"missing {path}"


def test_sql_readme_defines_drafts_and_validated_policy():
    readme = (ROOT / "sql" / "README.md").read_text(encoding="utf-8")
    assert "drafts" in readme
    assert "validated" in readme
    assert "examples" in readme
    assert "main_query.sql" in readme
    assert "validation_query.sql" in readme
    assert "query_note.md" in readme


def test_readme_describes_integrated_db_analysis_goal():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    assert "統合DB構築・分析スキル" in readme
    assert "構築系" in readme
    assert "探索系" in readme
    assert "分析系" in readme
    assert "mysql-create-query-support" in readme


def test_agents_mentions_read_only_reference_dirs_and_sql_policy():
    agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    assert "参照専用" in agents
    assert "OSX_IDE_Skill_management_Gemini" in agents
    assert "sql/" in agents
    assert "mysql-create-query-support" in agents


def test_existing_db_skills_link_to_query_support():
    skill_paths = [
        ".agent/skills/flat-file-mysql-overview/SKILL.md",
        ".agent/skills/mysql-er-diagram/SKILL.md",
        ".agent/skills/mysql-table-cardinality/SKILL.md",
        ".agent/skills/mysql-entity-matrix/SKILL.md",
        ".cursor/skills/flat-file-mysql-overview/SKILL.md",
        ".cursor/skills/mysql-er-diagram/SKILL.md",
        ".cursor/skills/mysql-table-cardinality/SKILL.md",
        ".cursor/skills/mysql-entity-matrix/SKILL.md",
    ]
    for rel in skill_paths:
        content = (ROOT / rel).read_text(encoding="utf-8")
        assert "mysql-create-query-support" in content, rel

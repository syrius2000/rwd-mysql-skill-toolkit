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


def test_query_support_skill_exists_in_agent():
    for rel in REQUIRED_RELATIVE_FILES:
        path = ROOT / ".agent/skills" / SKILL / rel
        assert path.exists(), f"missing {path}"


def test_cursor_skill_mirror_is_not_tracked():
    assert not (ROOT / ".cursor/skills").exists()


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
    assert "RWDデータワークフローの実行・統合ハブ" in readme
    assert "DB構築・探索（7）" in readme
    assert "RWD実行・品質（3）" in readme
    assert "VCD統合ミラー（4）" in readme
    assert "mysql-create-query-support" in readme


def test_agents_describes_external_sources_and_sql_policy():
    agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    assert "Productivity-Skill" in agents
    assert "agentic-evidence-analysis" in agents
    assert "ローカル管理Skillは14件" in agents
    assert "sql/" in agents
    assert "mysql-create-query-support" in agents


def test_existing_db_skills_link_to_query_support():
    skill_paths = [
        ".agent/skills/flat-file-mysql-overview/SKILL.md",
        ".agent/skills/mysql-er-diagram/SKILL.md",
        ".agent/skills/mysql-table-cardinality/SKILL.md",
        ".agent/skills/mysql-entity-matrix/SKILL.md",
    ]
    for rel in skill_paths:
        content = (ROOT / rel).read_text(encoding="utf-8")
        assert "mysql-create-query-support" in content, rel


def test_reference_analysis_skills_are_local_integration_mirrors():
    optional_skills = [
        "vcd-categorical-reporting",
        "vcd-bayesian-evidence-analysis",
    ]
    for skill in optional_skills:
        agent_dir = ROOT / ".agent/skills" / skill
        assert agent_dir.exists(), f"missing {agent_dir}"
        assert (agent_dir / "SKILL.md").exists(), f"missing {agent_dir / 'SKILL.md'}"

    bayesian = (
        ROOT / ".agent/skills/vcd-bayesian-evidence-analysis/SKILL.md"
    ).read_text(encoding="utf-8")
    assert "run_shell_command" not in bayesian
    assert "write_file" not in bayesian
    assert "sql/validated/" in bayesian
    assert (
        ROOT / ".agent/skills/vcd-bayesian-evidence-analysis/templates/analysis.R"
    ).exists()
    assert (
        ROOT / ".agent/skills/vcd-bayesian-evidence-analysis/templates/dashboard.Rmd"
    ).exists()
    assert (
        ROOT / ".agent/skills/vcd-categorical-reporting/references/interface.md"
    ).exists()


def test_readme_lists_brought_forward_analysis_skills():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    assert "vcd-categorical-reporting" in readme
    assert "vcd-bayesian-evidence-analysis" in readme

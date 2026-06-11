# Wiki Skill

Personal LLM Knowledge Base skill for maintaining Obsidian-style research wikis.

## Install

Recommended: use Codex's built-in skill installer:

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo liuyuqing803/wiki-skill \
  --path . \
  --name wiki
```

Fallback: clone the whole skill folder into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/liuyuqing803/wiki-skill.git ~/.codex/skills/wiki
```

If you already have this skill installed, update it with:

```bash
git -C ~/.codex/skills/wiki pull --ff-only
```

After installing, restart Codex or start a new session if the skill list does not refresh immediately.

## Contents

- `SKILL.md` - main skill workflow and guardrails.
- `agents/openai.yaml` - OpenAI-facing agent metadata.

## Purpose

Use this skill to ingest raw research sources, compile markdown wiki pages, answer questions against curated indexes, generate reusable outputs, and run health checks.

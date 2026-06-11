# Wiki Skill

Personal LLM Knowledge Base skill for maintaining Obsidian-style research wikis.

## Install

Install the skill into the shared agent skills directory:

```bash
mkdir -p ~/.agents/skills && git clone https://github.com/liuyuqing803/wiki-skill.git ~/.agents/skills/wiki
```

## Contents

- `SKILL.md` - main skill workflow and guardrails.
- `agents/openai.yaml` - OpenAI-facing agent metadata.

## Purpose

Use this skill to ingest raw research sources, compile markdown wiki pages, answer questions against curated indexes, generate reusable outputs, and run health checks.

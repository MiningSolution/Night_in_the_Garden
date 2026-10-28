# Night in the Garden — notes for Claude

Roblox farming / spirit-collection game (Luau, Rojo 7.x). The owner (Ruslan) writes in Russian:
reply in Russian; code, commits and repo docs stay in English.

## Read first

- `.specify/memory/constitution.md` — project principles (server-authoritative, single config
  source, Rojo + static GUI, mobile-first input-agnostic UI, theme tokens, verified in Studio,
  small PRs). Plans must pass its Constitution Check.
- `Docs/HANDOFF.md` — current state and next steps.
- `README.md` — layout and how the static GUI is generated.

## Workflow

- Features go through Spec Kit skills: `/speckit-specify` → `/speckit-clarify` →
  `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`. Specs live in `specs/NNN-name/`;
  the active feature is in `.specify/feature.json`.
- Branch per feature, PR to `main`; the owner reviews and merges.
- Every change is playtested in Roblox Studio (Studio MCP) with no new Output errors, and the
  repo and Studio stay identical (scripts and GUI).

## Conventions

- File suffix decides the class: `.server.lua` Script, `.client.lua` LocalScript, `.lua`
  ModuleScript, `.model.json` instances.
- Static GUI: edit `Tools/StaticGui/builders/*.luau`, then regenerate
  `python3 Tools/StaticGui/build_models.py <path-to-luau>`; never build whole screens at runtime.
- Balance/config numbers only in `ReplicatedStorage` config modules; never duplicated.
- Server validates every remote; the client only renders and requests.

# Research: Mobile UI Access (001)

Inputs collected before `/speckit-plan`, from comparing the spec with Grow a Garden and Roblox
guidance on 2026-10-28. `/speckit-plan` extends this file.

## R1. Disable the default Roblox backpack

- **Decision**: Turn off the CoreGui Backpack (`StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)`)
  on the client at startup; the game's own hotbar is the only tool bar.
- **Rationale**: while the CoreGui Backpack is enabled, `ButtonL1`/`ButtonR1` cannot be bound
  through ContextActionService, which FR-013a needs for hotbar cycling
  ([DevForum](https://devforum.roblox.com/t/binding-keycode-buttonl1buttonr1-through-contextactionservice-not-possible-with-backpack-coregui/21767)).
  The repo has no `SetCoreGuiEnabled` call today, so the default backpack is still on.
- **Alternatives considered**: other hotbar buttons (D-pad) — rejected, the D-pad is reserved for
  highlight navigation inside windows (FR-013a).

## R2. Window layout: Scale frame, Offset content

- **Decision**: each window's outer container is sized by Scale with aspect-ratio and size
  constraints (85% of the free height above the hotbar on phones, at most 60% of screen height on
  tablet/PC, FR-004); rows, buttons and text inside use fixed Offset sizes and layouts, with a
  scrolling list where contents can exceed the window (FR-006).
- **Rationale**: Roblox normalises Offset and TextSize to about 160 dpi, so Offset content keeps a
  constant physical size across devices; layouts built entirely on Scale become unreadably small
  on phones and break across aspect ratios
  ([DevForum, UI scaling best practices](https://devforum.roblox.com/t/specific-details-about-ui-scaling-best-practices/3888004)).
  The same thread states the Roblox top bar is 36 px high, which the safe-area layout must
  respect. Console guidelines also call for size constraints and scrolling frames
  ([Roblox Docs](https://create.roblox.com/docs/production/publishing/console-guidelines)).
- **Alternatives considered**: pure Scale with `TextScaled` everywhere (original Phase 1 plan
  wording) — rejected for the reason above; `TextScaled` stays only where a label must shrink to
  fit, bounded by `UITextSizeConstraint` with MinTextSize 18 (body) / 20 (titles, buttons).

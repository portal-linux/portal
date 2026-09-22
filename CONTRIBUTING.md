# Contributing to Portal

Thanks for your interest in Portal. This document explains how we work.

## Commit rights

Commit rights are earned, not granted up front. The rule: 3 merged PRs plus one release cycle of activity earns commit rights. This keeps the maintainer group made up of people who have shown sustained, real involvement in the project.

## Proposals and discussion

Use GitHub Discussions for proposals. Open a discussion before a large or cross-cutting change so the direction can be agreed on before code is written. Small fixes can go straight to a pull request.

## Architectural decisions

Architectural decisions are recorded as ADRs in `docs/adr/`. When a change alters the architecture of the project, add an ADR describing the context, the decision, and the consequences. See the existing ADRs for the format.

## Relationship to Asahi Linux

Portal integrates with but never forks Asahi Linux's drivers. We build on Apple's Virtualization.framework and cooperate with the Asahi project's work upstream rather than maintaining a divergent copy of it.

## Development

```
swift build
swift test
```

Follow test-driven development: write a failing test first, then the minimal code to pass it, then refactor. Keep files small and focused.

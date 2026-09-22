# 1. Record architecture decisions

Date: 2026-09-22

## Status

Accepted

## Context

We need a lightweight, durable way to capture the architectural decisions made on Portal, including the context that led to each decision and the consequences that follow from it. Decisions made in chat or in pull request threads are easily lost.

## Decision

We will keep a collection of Architecture Decision Records (ADRs) in `docs/adr/`. Each record is a short markdown file, numbered in sequence, describing one decision: its context, the decision itself, and its consequences.

## Consequences

Contributors get a written history of why the project is shaped the way it is. New ADRs are added as part of the pull request that makes the corresponding change, so the record stays close to the code and stays current.

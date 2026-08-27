---
name: dk-infrastructure
description: Use when working on DK Digital Bank Terraform, Atlantis, GitLab-project, self-service, provisioner, blueprint, GitLab Runner, or DevEx Tools and Platform ownership boundaries.
---

# DK Infrastructure

## Ownership

- DevEx Tools owns SaaS stacks and service-specific automation under `dev-ex/tools/**`, including Redis, Temporal, Aiven, and Harness.
- Platform owns GCP/AWS foundations and shared execution infrastructure, including Atlantis and GitLab runners, primarily under `platform/**`.
- Namespace is the default ownership signal. Check `CODEOWNERS` for exceptions.
- Cross-team Platform MRs are allowed when a shared foundation needs a change.

## Repository Layers

- A self-service or tool repository declares tenant resources.
- A provisioner implements Terraform behavior.
- A blueprint deploys shared or foundational components.
- `dev-ex/misc/gitlab-project` manages GitLab groups, projects, webhooks, merge access, and approvals.

## Atlantis Routing

- A control-plane workspace's `provisioner.instance` selects the Atlantis that applies that workspace.
- `common.hook.<repo-type>` configures the GitLab webhooks that route managed repository events to Atlantis endpoints.
- A consumer workspace's `provisioner.instance` and backend select its environment execution and Terraform state.
- Tenant endpoints, users, secret names, backend buckets, and provisioner versions are live configuration: read them from the relevant repository; do not rely on memory.

## GitLab-Project Preflight

Before adding a GitLab-project workspace or `app.group`:

1. Inspect the closest tenant/reference configuration.
2. Query each ancestor GitLab group and identify the existing state/workspace that owns it.
3. Set `common.root_group` to the deepest existing ancestor that this workspace must not create.
4. Ensure `app.group` is a descendant of that root; this workspace creates only missing descendants.
5. Use `import` for an existing project that the workspace begins managing.
6. Review the Atlantis plan: unexpected creation of an existing ancestor group means the root or state ownership is wrong.

Example: for a new project under `dk-digital-bank/dev-ex/tools/phbank/redis`, when `tools` and `phbank` already exist, set `common.root_group: "dk-digital-bank/dev-ex/tools/phbank"`. The workspace then creates `redis`, not its shared ancestors.

## Fast Path

Use a close working example, then verify live GitLab groups and state ownership before editing. Do not broaden repository investigation after a valid reference and ownership boundary are established.

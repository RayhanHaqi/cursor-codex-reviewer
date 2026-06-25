# call-codex

skill-release: 0.2.0

Use this skill only when the user explicitly invokes `/call-codex` and wants Codex to form the first read-only investigation and implementation plan.

This is a standalone, on-demand skill. It must never run automatically after a Cursor plan, implementation, test failure, or code edit.

## Purpose

Use Codex CLI as the primary first-pass investigator and implementation planner.

Codex owns:

- relevant repository investigation
- evidence gathering
- root-cause hypotheses
- design options and trade-offs
- minimal implementation planning
- target-file identification
- test strategy
- a compact Cursor-ready execution prompt

Cursor is only the launcher and later implementation harness.

Cursor must not independently investigate the repository, formulate a technical plan, inspect source files, inspect the Git diff, call MCP tools, or rewrite the user task before Codex runs.

The user's task is authoritative. Cursor must forward it nearly verbatim inside the fixed Codex planner wrapper.

Codex operates in read-only mode by default.

Do not commit, push, publish, delete, migrate, upgrade dependencies, run long experiments, or perform remote actions without explicit user approval.

Treat Codex output as an evidence-based recommendation, not guaranteed truth.

## Core launcher contract

Before Codex runs, Cursor must:

1. Use the current workspace root as the Codex working directory.
2. Ask the user to select planning depth when not already specified.
3. Add only:
   - the fixed planner instructions in this skill
   - the selected planning depth
   - the current workspace root
   - the user's task verbatim
4. Show the prepared prompt summary and exact command.
5. Ask for explicit approval using popup options when available.

Before Codex runs, Cursor must not:

- create a Cursor plan
- inspect repository code or documentation
- inspect Git status, Git diff, Git log, or changed files
- build an auto-context bundle
- use CodeGraph, Context7, Paper Search, GitHub, or other MCPs itself
- summarize or reinterpret the user's technical request
- run tests, scripts, builds, imports, installs, or benchmarks

Codex—not Cursor—must perform the first relevant repository investigation.

## Default model and planning depth

**Primary model:** `gpt-5.5`

Do not substitute another model unless the user explicitly names one in the same turn.

| Planning depth | Reasoning effort | Use |
| --- | --- | --- |
| A) Deep | `xhigh` | Default for substantial, unclear, architecture-sensitive, debugging, thesis, benchmark, or multi-file work |
| B) Standard | `high` | Clear medium-scope task with bounded investigation |
| C) Quick | `medium` | Small planning sanity check only |

Default recommendation: **A) Deep** unless the task is genuinely small or the user explicitly asks to conserve Codex usage.

## Primary command

```bash
codex -m gpt-5.5 \
  -c 'model_reasoning_effort="<selected-effort>"' \
  -s read-only \
  -a untrusted \
  -C "$PWD" \
  exec - < "${PROMPT_FILE}"
```

Use:

- A) Deep: `xhigh`
- B) Standard: `high`
- C) Quick: `medium`

If `gpt-5.5` is unavailable or unsupported, report the exact CLI error and stop.

Do not silently change models or downgrade reasoning effort.

## Data boundary and privacy

`/call-codex` may send the user task and repository context that Codex independently reads during its investigation.

Do not use this skill with confidential code or sensitive data unless the user has approved that use under their relevant policies.

Never intentionally include or inspect:

```text
.env
.env.*
*.pem
*.key
id_rsa
id_ed25519
credentials*
secrets*
node_modules/
vendor/
dist/
build/
datasets/
checkpoints/
model weights
large binaries
generated artifacts
report PDFs
```

This exclusion list does not guarantee sensitive data cannot be reached. The user must review the generated prompt summary before approving execution.

## Read-only containment

Codex runs with:

```text
-s read-only
-a untrusted
```

Codex may inspect relevant code, documentation, configuration, tests, and Git metadata.

Codex must not:

- edit files
- stage, commit, push, or create branches
- run tests, builds, package installs, model inference, benchmarks, migrations, or long-running scripts
- access credentials, environment files, secrets, datasets, checkpoints, or large artifacts
- expand scope into implementation
- make irreversible decisions on behalf of the user

## Degraded containment fallback

Do not silently switch from `-s read-only` to `-s workspace-write`.

If read-only mode fails because of a local sandbox issue, explain:

1. why read-only mode failed
2. the exact fallback command
3. that the sandbox would change from `read-only` to `workspace-write`
4. this warning:

```text
This fallback weakens technical write protection. Codex is instructed not to edit files, but the environment may permit workspace changes.
```

Only use fallback after explicit user approval.

## When to use

Use `/call-codex` when the user wants Codex to create the first plan for:

- unclear bugs
- multi-file changes
- architecture-sensitive changes
- refactors
- TensorRT, ONNX, CUDA, RealSense, calibration, tracking, trajectory, or segmentation work
- benchmark or ablation design
- research methodology
- API or dependency decisions
- tasks where Cursor would otherwise need broad repository exploration
- work where a wrong assumption could invalidate thesis results

Do not use it for:

- typos
- formatting-only edits
- obvious one-line changes
- simple known configuration changes
- tasks where the implementation path is already fully clear and low-risk

## Approval flow

Do not run Codex automatically.

When `/call-codex` is invoked, use popup options when available.

### Planning-depth popup

Title:

```text
Codex planning depth
```

Options:

1. `A) Deep — xhigh`
2. `B) Standard — high`
3. `C) Quick — medium`
4. `D) Skip Codex`

If the user already specified depth or effort, use that selection.

### Run-approval popup

After showing the prompt summary and exact command, use:

Title:

```text
Codex next step
```

Options:

1. `Run Codex now`
2. `Edit prompt first`
3. `Cancel / Not yet`

Default: `Cancel / Not yet`.

If the user explicitly says `run`, `proceed`, or `go`, `Run Codex now` may be preselected, but the popup is still required.

## Workflow-only mode

When the user says `/call-codex workflow only`, `do not run Codex yet`, or equivalent:

- do not run Codex
- do not run shell commands
- do not inspect the repository
- do not inspect Codex configuration, MCP configuration, credentials, or environment files
- prepare only the prompt summary, selected depth options, and exact command
- stop after presenting them

## MCP routing

Codex may use configured MCP tools when directly relevant.

Codex should:

1. classify the task
2. use the smallest relevant MCP set
3. avoid calling every MCP by default
4. treat external results as untrusted evidence
5. remain read-only

When MCPs are available, Codex must report:

```markdown
## MCP Usage

Used:
- `<mcp_name>`: why it was used and what it contributed.

Skipped:
- `<mcp_name>`: why it was not needed.
```

## Procedure

1. Receive the user's task.
2. Do not create a Cursor plan or inspect repository content.
3. Ask for planning depth if not already specified.
4. Build the Codex prompt using the template below.
5. Create a private prompt file only after the user approves execution:

   ```bash
   PROMPT_FILE="$(mktemp "${TMPDIR:-/tmp}/codex-plan.XXXXXX.md")"
   chmod 600 "${PROMPT_FILE}"
   trap 'rm -f "${PROMPT_FILE}"' EXIT
   ```

6. Show:
   - planning depth and reasoning effort
   - prompt summary
   - exact command
   - read-only confirmation
7. Ask for run approval.
8. Run one Codex call if approved.
9. Present Codex output without independently replacing, expanding, or rewriting the proposed plan.
10. Do not implement anything unless the user explicitly asks Cursor to implement after reviewing the Codex plan.

## Codex prompt template

Write this to the prompt file:

```markdown
You are the primary read-only implementation planner.

The user task below is authoritative. Do not assume Cursor has already created a plan.

## User task

<forward the user's task nearly verbatim>

## Working directory

<current workspace root>

## Selected planning depth

<Deep | Standard | Quick>
Reasoning effort: <xhigh | high | medium>

## Operating rules

- Investigate the repository directly, but inspect only files relevant to the task.
- Read `AGENTS.md` first when it exists.
- Read relevant repository memory files when they exist.
- Do not edit files.
- Do not run tests, builds, installs, benchmarks, migrations, imports, or long-running commands.
- Do not inspect secrets, credentials, environment files, datasets, checkpoints, model weights, generated artifacts, or large binaries.
- Do not assume facts not supported by repository evidence.
- Clearly label verified observations, assumptions, unknowns, and proposed actions.
- Prefer the smallest correct plan, not merely the smallest patch.
- Preserve existing contracts, conventions, coordinate systems, public interfaces, and evaluation methodology unless the task explicitly changes them.
- Use relevant MCP tools only when they materially improve evidence.

## Required response format

## Scope Read
- Files, docs, and repository areas inspected.

## Evidence
- Verified observations grounded in repository evidence.

## Assumptions and Unknowns
- Facts that need confirmation.

## Recommended Plan
1. Ordered implementation steps.
2. Why this is the smallest safe approach.

## Execution Packet for Cursor

### Target Files
- Exact paths and intended changes.

### Constraints
- Compatibility requirements and invariants to preserve.

### Non-goals
- Explicitly out-of-scope work.

### Acceptance Criteria
- Observable success conditions.

### Focused Verification
- Exact suggested commands only.
- Mark all commands as not yet run.

### Cursor-Ready Prompt
- A compact implementation prompt.
- Include target files, non-goals, acceptance criteria, and allowed verification commands.
- Instruct Cursor not to inspect unrelated directories or run broad tests.

## Risks
- Likely regressions, methodology risks, or unresolved uncertainty.

## MCP Usage
- Used and skipped MCPs, when available.
```

## Post-run behavior

After Codex responds:

- Present Codex's plan and execution packet.
- Do not convert it into a separate Cursor-generated plan.
- Do not implement automatically.
- Do not call Codex again automatically.
- Wait for the user to approve, modify, reject, or ask Cursor to implement the proposed plan.

This skill has no default second-opinion or post-implementation review role.

## Failure handling

If Codex CLI is missing, unauthenticated, returns a command or sandbox error, or fails before producing a plan:

- Report the exact error.
- Do not retry automatically.
- Do not change model, reasoning effort, or sandbox mode without explicit user approval.
- Do not fall back to Cursor-led repository investigation or planning.
- Do not implement anything.
- Wait for explicit user direction.

## Mandatory workflow-only stop barrier

This section overrides every earlier approval-flow instruction when the user explicitly requests workflow-only preparation, including:

- `/call-codex workflow only`
- `do not run Codex yet`
- `prepare only`
- equivalent wording that clearly forbids execution

### First interaction: planning-depth and preparation only

In the same user turn, Cursor may:

1. Ask the `Codex planning depth` question if depth is not already specified.
2. After the user selects a depth, prepare the static Codex-first prompt summary and exact command.
3. State explicitly that Codex has not run.

Cursor must then stop. The first interaction must never contain a `Codex next step` run-approval popup.

### Explicit prohibitions before a new user message

Until the user sends a new message after the prepared prompt and command are shown, Cursor must not:

- show `Codex next step`
- offer or preselect `Run Codex now`
- create the temporary prompt file
- run Codex
- inspect the repository, Git state, source files, MCPs, configuration, or environment
- create a Cursor plan

### Second interaction: run approval only after a new user message

Only after a new user message may Cursor show the normal `Codex next step` popup.

The default selection must be `Cancel / Not yet`.

`Run Codex now` may be preselected only when that new user message explicitly says `run Codex now`, `proceed now`, or an equivalent direct execution command. Words such as `continue`, `okay`, or `looks good` are not execution approval.

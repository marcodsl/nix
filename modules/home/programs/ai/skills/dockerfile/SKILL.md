---
name: dockerfile
description: "Write and review Dockerfiles with multi-stage builds, reproducible base images, cache-efficient layers, and container hardening. Use when: creating or reviewing Dockerfiles, shrinking images, improving build caching, choosing base images, or tightening container security."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: dockerfile, containers, multi-stage-builds, image-hardening, build-cache
---

# Dockerfile

Rules for writing and reviewing Dockerfiles with reproducible builds, minimal runtime images, explicit tradeoffs, and correctness-first validation.

## Purpose

Use this skill to write, review, or refactor Dockerfiles without drifting into cargo-cult image optimization. Prefer builds that are reproducible, cache-efficient, and operationally safe. Optimize image size and layer count only when the result still matches the application's runtime, debugging, and security requirements.

## Scope

### Use this skill when

- Writing a new Dockerfile for an application, service, worker, or CLI.
- Reviewing an existing Dockerfile for correctness, image size, caching, hardening, or maintainability.
- Choosing between single-stage and multi-stage builds, or restructuring stages to reduce rebuild cost.
- Evaluating base image, package install, file-copy, entrypoint, or runtime-user decisions.

### Do not use this skill when

- The task is mainly about Docker Compose, Kubernetes manifests, Helm charts, or container orchestration rather than the Dockerfile itself.
- The task is about CI wiring or registry policy and the Dockerfile only changes incidentally.
- The repository has a documented container policy that intentionally conflicts with these defaults and the task is not to change that policy.

## Governing rule

Build the smallest reproducible image that still matches the real runtime requirements. Separate build-time and runtime concerns, pin what matters, copy only what is needed, and do not trade away compatibility, debuggability, or safety for a headline image-size win.

## Investigation before changes

Read the surrounding build surface before making claims or edits.

1. Read the Dockerfile end to end before proposing improvements.
2. Read `.dockerignore`, dependency manifests, startup scripts, and the app entrypoint before changing copy order, install steps, or runtime commands.
3. Identify native dependencies, shell requirements, CA certificate needs, timezone expectations, and libc assumptions before recommending Alpine or distroless images.
4. If the repository already has container conventions, optimize within those constraints instead of rewriting the whole approach.

## Review workflow

Review Dockerfiles in this order so the biggest risks surface first.

1. **Build and runtime correctness**: stages, copied artifacts, entrypoint, environment, ports, and runtime dependencies.
2. **Security and hardening**: base image trust, non-root execution, secret handling, package footprint, and unnecessary tooling in the final image.
3. **Caching and rebuild cost**: layer order, dependency install boundaries, `.dockerignore`, and cache mount opportunities.
4. **Maintainability and image size**: stage naming, repetition, cleanup strategy, and whether optimizations make the file harder to operate.

For each real concern, name the concrete risk, cite the relevant stage or instruction, explain the tradeoff, and recommend the option that best fits the repository's goals. Do not nitpick stylistic issues that do not materially affect correctness, security, or rebuild cost.

## Dockerfile design defaults

### Multi-stage boundaries

- Prefer multi-stage builds when the project compiles code, installs build-only tooling, or can copy a small set of runtime artifacts into a final stage.
- Use explicit stage names (`AS deps`, `AS build`, `AS test`, `AS runtime`) when a stage has a stable role.
- Keep test tools, compilers, package managers, and source trees out of the final image unless the container genuinely needs them at runtime.
- Split stages only when the split improves caching, isolation, or readability. Do not create extra stages with no practical benefit.

### Base images

- Prefer official or clearly trusted base images with a small footprint and an update cadence that matches the project's security posture.
- Pin a concrete version tag. Pin by digest when reproducibility or supply-chain control matters.
- Recommend Alpine only when musl compatibility, debugging needs, and native dependencies are understood. Do not assume "smaller" means "better."
- Recommend distroless only when the runtime can tolerate a shell-less, package-manager-free image and the team can still debug and operate it comfortably.
- Keep builder and runtime libc expectations aligned when native extensions, shared libraries, or compiled binaries are involved.

### Layer ordering and caching

- Put low-churn inputs first: base image selection, OS package installs, dependency manifests, and lockfiles before application source.
- Copy only the files needed for dependency installation before running the install step.
- Keep package installation and package-cache cleanup in the same `RUN` instruction so temporary artifacts do not persist in earlier layers.
- Use BuildKit cache mounts when the project and build environment already support them and the change materially improves rebuild time.
- Keep `.dockerignore` tight so local caches, VCS data, build artifacts, secrets, and editor junk do not enter the build context.

### File copying and ownership

- Prefer `COPY` over `ADD` unless remote URL fetch or archive auto-extraction is genuinely required.
- Copy the narrowest set of files possible into each stage. Do not `COPY . .` early unless the whole tree is required at that point.
- Use `COPY --chown` when ownership needs to change and the syntax is available, rather than adding a follow-up `chown` layer.
- Set `WORKDIR` explicitly and keep relative paths predictable across stages.

### Runtime hardening

- Run the final container as a non-root user unless the workload truly requires elevated privileges.
- Keep secrets out `ARG`, `ENV`, and image layers. Prefer build secrets or runtime injection for sensitive values.
- Prefer exec-form `ENTRYPOINT` and `CMD` so signal handling and process shutdown behave correctly.
- Add a `HEALTHCHECK` only when the platform uses it and the probe is meaningful; avoid performative checks that add noise without improving recovery.
- Set only the environment variables the process actually needs. Keep build-time `ARG` and runtime `ENV` responsibilities distinct.

### Package installs and cleanup

- For Debian and Ubuntu bases, prefer `apt-get update && apt-get install --no-install-recommends ...` in one layer, then remove apt lists in that same layer.
- For Alpine bases, avoid blanket `apk upgrade` unless the project has a documented reason; install the minimum required packages and clean up when appropriate.
- Do not leave curl, compilers, or debugging utilities in the runtime image unless they are operational requirements.
- Prefer copying prebuilt artifacts from earlier stages over reinstalling the same dependencies in the runtime stage.

## Tradeoff defaults

When multiple approaches are reasonable, make the tradeoff explicit instead of presenting one pattern as universally correct.

- **Alpine vs slim Debian/Ubuntu**: choose Alpine for size only when musl compatibility is proven; choose slim glibc-based images when compatibility and operational simplicity matter more.
- **Distroless vs minimal distro runtime**: choose distroless for hardened, stable production runtimes; choose a minimal distro runtime when shell access, package inspection, or on-call debugging still matters.
- **Single-stage vs multi-stage**: choose multi-stage when build tooling should not ship; choose single-stage only for truly simple runtimes where the added complexity buys little.
- **Fewer layers vs clearer layers**: merge commands when it removes disposable artifacts or improves caching; keep separate layers when combining them would hide intent or make diffs harder to reason about.

## Patterns to correct

- Unpinned `FROM` images such as `latest` or floating major tags with no documented reason.
- Early `COPY . .` before dependency installation, which invalidates cache on every source change.
- Runtime stages that still contain build tools, package-manager caches, test artifacts, or the full source tree.
- `ADD` used for ordinary local file copies.
- Final images that run as root without a concrete need.
- Shell-form `CMD` or `ENTRYPOINT` for long-running processes that should receive signals directly.
- Secrets, tokens, or credentials baked into `ARG`, `ENV`, copied config files, or generated layers.
- Recommending Alpine, distroless, or aggressive layer collapsing purely for aesthetics without checking runtime impact.

## Verification defaults

Treat Dockerfile work as incomplete until the image behavior is checked at the level the change warrants.

1. **Build**: build the relevant target and confirm every stage resolves with the expected files and dependencies.
2. **Run**: start the container with the expected command and confirm the process boots, handles signals, and can read the files it needs.
3. **Inspect**: verify the runtime user, entrypoint, environment, copied artifacts, and exposed ports match the intended runtime shape.
4. **Size and composition**: if the goal includes optimization, compare image size, layer composition, or copied contents before claiming improvement.
5. **Security posture**: if the change affects base images, packages, or secrets, review whether the final image still avoids unnecessary tooling and does not persist sensitive material.

## Verification checklist

- [ ] The `description` contains high-signal discovery terms for Dockerfile authoring, review, caching, image size, and hardening.
- [ ] The skill stays scoped to Dockerfiles rather than drifting into orchestration or CI policy.
- [ ] The guidance is actionable and written as behavior rules rather than generic best-practice filler.
- [ ] The skill tells the model to investigate the real build surface before recommending Alpine, distroless, or other high-impact changes.
- [ ] The skill makes tradeoffs explicit when image size, compatibility, security, and operability pull in different directions.
- [ ] The verification steps cover build correctness, runtime behavior, and image composition.

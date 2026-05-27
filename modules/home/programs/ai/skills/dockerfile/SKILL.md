---
name: dockerfile
description: "Write and review Dockerfiles with multi-stage builds, pinned base images, cache-efficient layers, and container hardening. Triggers: `Dockerfile`, `FROM`, `RUN apt-get`, `COPY`/`ADD`, `ENTRYPOINT`/`CMD`, `.dockerignore`, multi-stage refactor, image shrinking, picking Alpine vs slim Debian vs distroless, non-root user, BuildKit cache mounts, `WORKDIR`, `HEALTHCHECK`. Skip when: the task is Docker Compose, Kubernetes manifests, Helm charts, or container orchestration with no Dockerfile change."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: dockerfile, containers, multi-stage-builds, image-hardening, build-cache
  version: 3
---

# Dockerfile

<purpose>
Write, review, or refactor Dockerfiles with reproducible builds, minimal runtime images, explicit tradeoffs, and correctness-first validation. Optimize size and layer count only when the result still matches runtime, debugging, and security requirements.
</purpose>

<scope>
  <use_when>
  - Writing a new Dockerfile for an application, service, worker, or CLI.
  - Reviewing an existing Dockerfile for correctness, image size, caching, hardening, or maintainability.
  - Choosing between single-stage and multi-stage builds.
  - Evaluating base image, package install, file-copy, entrypoint, or runtime-user decisions.
  </use_when>

  <do_not_use_when>
  - The task is mainly Docker Compose, Kubernetes, Helm, or orchestration rather than the Dockerfile itself.
  - The task is CI wiring or registry policy and the Dockerfile only changes incidentally.
  - The repository has a documented container policy that intentionally conflicts with these defaults.
  </do_not_use_when>
</scope>

<governing_rule>
Build the smallest reproducible image that still matches real runtime requirements. Separate build-time and runtime concerns, pin what matters, copy only what is needed, and do not trade away compatibility, debuggability, or safety for a headline image-size win.
</governing_rule>

<working_method>
1. Investigate the build surface before changes: read the Dockerfile end to end, `.dockerignore`, manifests, startup scripts, and the entrypoint. Identify native deps, shell requirements, CA cert needs, timezone expectations, and libc assumptions before recommending Alpine or distroless.
2. Review in this order so the biggest risks surface first:
   a. Build and runtime correctness: stages, copied artifacts, entrypoint, env, ports, runtime deps.
   b. Security and hardening: base image trust, non-root, secrets, package footprint, tooling in final image.
   c. Caching and rebuild cost: layer order, dependency install boundaries, `.dockerignore`, cache mounts.
   d. Maintainability and image size: stage naming, repetition, cleanup, whether optimizations hurt operability.
3. For each real concern, name the risk, cite the stage or instruction, explain the tradeoff, and recommend an option. Skip stylistic nitpicks.
4. Verify build, runtime, inspection, size, and security posture before claiming the change is complete.
</working_method>

<section name="multi-stage">
- Prefer multi-stage when the project compiles code, installs build-only tooling, or can copy a small runtime artifact set.
- Use explicit stage names (`AS deps`, `AS build`, `AS test`, `AS runtime`).
- Keep test tools, compilers, package managers, and source trees out of the final image unless genuinely needed at runtime.
- Split stages only when caching, isolation, or readability improves. Do not create stages with no practical benefit.
</section>

<section name="base-images">
- Prefer official or clearly trusted base images with a small footprint and appropriate update cadence.
- Pin a concrete version tag. Pin by digest when reproducibility or supply-chain control matters.
- Alpine: only when musl compatibility, debugging needs, and native deps are understood. "Smaller" is not automatically "better".
- Distroless: only when the runtime tolerates shell-less, package-manager-free images and the team can still debug and operate.
- Keep builder and runtime libc aligned for native extensions or compiled binaries.
</section>

<section name="layer-ordering">
- Put low-churn inputs first: base image, OS packages, dependency manifests, lockfiles — then application source.
- Copy only the files needed for dependency install before running install.
- Package install and cache cleanup in the same `RUN` so temporary artifacts do not persist in earlier layers.
- Use BuildKit cache mounts when the project and environment support them and rebuild time materially improves.
- Keep `.dockerignore` tight: no local caches, VCS data, build artifacts, secrets, or editor files.
</section>

<section name="copy-and-ownership">
- Prefer `COPY` over `ADD` unless remote URL fetch or archive auto-extraction is genuinely required.
- Copy the narrowest file set into each stage. Avoid early `COPY . .` unless the whole tree is needed at that point.
- Use `COPY --chown` rather than a follow-up `chown` layer.
- Set `WORKDIR` explicitly; keep relative paths predictable across stages.
</section>

<section name="runtime-hardening">
- Run the final container as non-root unless the workload truly requires elevated privileges.
- Keep secrets out of `ARG`, `ENV`, and image layers. Use build secrets or runtime injection.
- Prefer exec-form `ENTRYPOINT` and `CMD` for correct signal handling.
- Add `HEALTHCHECK` only when the platform uses it and the probe is meaningful.
- Set only the env vars the process actually needs. Keep `ARG` (build-time) and `ENV` (runtime) responsibilities distinct.
</section>

<section name="package-installs">
- Debian/Ubuntu: `apt-get update && apt-get install --no-install-recommends ...` in one layer; remove apt lists in the same layer.
- Alpine: avoid blanket `apk upgrade` without a documented reason; install the minimum required and clean up.
- Do not leave curl, compilers, or debugging utilities in the runtime image unless operationally required.
- Prefer copying prebuilt artifacts from earlier stages over reinstalling deps in the runtime stage.
</section>

<section name="tradeoffs">
When more than one approach is reasonable, name the tradeoff explicitly:
- Alpine vs slim Debian/Ubuntu: Alpine for size only when musl compatibility is proven; slim glibc for compatibility and operational simplicity.
- Distroless vs minimal distro: distroless for hardened production; minimal distro when shell access, package inspection, or on-call debugging still matters.
- Single-stage vs multi-stage: multi-stage when build tooling should not ship; single-stage only for truly simple runtimes.
- Fewer vs clearer layers: merge to remove disposable artifacts or improve caching; keep separate when combining hides intent.
</section>

<section name="anti-patterns">
- Unpinned `FROM` (`latest`, floating major tags) with no documented reason.
- Early `COPY . .` before dependency installation.
- Runtime stages still containing build tools, caches, test artifacts, or the full source tree.
- `ADD` used for ordinary local file copies.
- Final images running as root without a concrete need.
- Shell-form `CMD`/`ENTRYPOINT` for long-running processes that should receive signals directly.
- Secrets, tokens, or credentials baked into `ARG`, `ENV`, copied configs, or layers.
- Alpine, distroless, or aggressive layer collapsing recommended for aesthetics without checking runtime impact.
</section>

<section name="verification">
1. Build: build the target; confirm every stage resolves with the expected files and dependencies.
2. Run: start the container with the expected command; confirm the process boots, handles signals, and reads needed files.
3. Inspect: verify runtime user, entrypoint, environment, copied artifacts, and exposed ports.
4. Size and composition: if optimization is the goal, compare image size, layer composition, or copied contents before claiming improvement.
5. Security: when base images, packages, or secrets changed, review that the final image avoids unnecessary tooling and persists no sensitive material.
</section>

<review_checklist>
- Skill stays scoped to Dockerfiles; no drift into orchestration or CI policy.
- Recommendations investigate the real build surface before high-impact changes (Alpine, distroless).
- Tradeoffs are explicit when image size, compatibility, security, and operability pull in different directions.
- Verification covers build correctness, runtime behavior, and image composition.
</review_checklist>

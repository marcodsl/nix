---
name: frontend-design
description: "Build distinctive, production-grade frontend interfaces in HTML/CSS/JS or React with a deliberate aesthetic direction (brutalist, editorial, retro-futuristic, refined minimal, etc.) so the output does not look like generic AI UI. Triggers: 'make it beautiful', 'design a landing page', 'style this component', 'build a dashboard UI', 'redesign', 'poster', 'mockup', or any prompt requesting visual polish on HTML/CSS/React. Skip when: the task is backend, infrastructure, API design, or purely about correctness with no visual concern."
license: Apache-2.0
metadata:
  author: anthropics
  source: https://github.com/anthropics/skills/tree/main/skills/frontend-design
  tags: frontend, ui, design, web, html, css, react, typography, aesthetics
  version: 3
---

# Frontend Design

<purpose>
Build distinctive, production-grade frontend interfaces. Implement working code with deliberate aesthetic commitment so the output does not read as generic AI output.
</purpose>

<scope>
  <use_when>
  - Building components, pages, artifacts, posters, or applications (landing pages, dashboards, React components, HTML/CSS layouts).
  - Styling or beautifying any web UI when aesthetic quality matters.
  - The user provides frontend requirements and wants a polished, opinionated result.
  </use_when>

  <do_not_use_when>
  - The task is backend-only, infrastructure, or API design.
  </do_not_use_when>
</scope>

<governing_rule>
Choose one bold conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work; the failure mode is timid, defaulted, undifferentiated output.
</governing_rule>

<working_method>
1. Frame the work: purpose (what problem, for whom), tone (extreme aesthetic direction), constraints (framework, performance, accessibility), differentiation (the one thing someone will remember).
2. Pick one aesthetic direction from the spectrum (brutally minimal, maximalist chaos, retro-futuristic, organic, luxury, playful, editorial, brutalist, art deco, pastel, industrial). Adapt the chosen direction; do not copy it.
3. Implement working code (HTML/CSS/JS, React, Vue) that is production-grade, visually striking, cohesive, and meticulously refined.
4. Match implementation complexity to the vision: maximalist needs elaborate animations and effects; refined needs restraint, precision, and care in spacing, typography, and subtle detail.
</working_method>

<section name="aesthetics">
- Typography: choose distinctive fonts that elevate the work. Pair a characterful display font with a refined body font. Avoid Inter, Roboto, Arial, system defaults.
- Color & theme: commit to a cohesive palette. Use CSS variables. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- Motion: prioritize CSS-only solutions for HTML; use Motion for React when available. Concentrate on high-impact moments. One orchestrated page-load with staggered reveals (animation-delay) beats scattered micro-interactions. Use scroll triggers and surprising hover states.
- Spatial composition: unexpected layouts, asymmetry, overlap, diagonal flow, grid-breaking elements. Choose generous negative space or controlled density deliberately.
- Backgrounds and visual detail: build atmosphere with gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, grain overlays. Solid colors are the fallback, not the default.
</section>

<section name="avoid">
- Overused fonts (Inter, Roboto, Arial, system stacks).
- Cliché schemes (purple gradients on white).
- Predictable layouts and component patterns.
- Cookie-cutter design with no context-specific character.
- Repeated convergence on the same "safe" choices (Space Grotesk and similar) across generations.

Vary themes (light vs dark), fonts, and aesthetic direction across outputs. No two designs should look the same.
</section>

<review_checklist>
- One clear aesthetic direction is named and executed throughout.
- Typography pairs are intentional and distinctive.
- Colors form a cohesive palette with deliberate dominance and accent.
- Motion is concentrated on high-impact moments, not scattered.
- Layout shows at least one unexpected composition choice (asymmetry, overlap, diagonal flow, grid break).
- Background and visual detail carry atmosphere; no plain default surfaces unless minimalism is the chosen direction.
- Code is functional and production-grade, not just decorative.
</review_checklist>

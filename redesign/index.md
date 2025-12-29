# Architectural Redesign Project

[This project was announced in the project's README](../README.md#2025-07-09-architectural-redesign)

The git gem is undergoing a significant architectural redesign for the upcoming
v5.0.0 release. The current architecture has several design challenges that make it
difficult to maintain and evolve. This redesign aims to address these issues by
introducing a clearer, more robust, and more testable structure.

We have prepared detailed documents outlining the analysis of the current
architecture and the proposed changes. We encourage our community and contributors to
review them:

1. [Analysis of the Current Architecture](1_architecture_existing.md): A
   breakdown of the existing design and its challenges.
2. [The Proposed Redesign](2_architecture_redesign.md): An overview of the
   new three-layered architecture.
3. [Implementation Plan](3_architecture_implementation.md): The step-by-step
   plan for implementing the redesign.

Your feedback is welcome! Please feel free to open an issue to discuss the proposed
changes.

> **DON'T PANIC!**
>
> While this is a major internal refactoring, our goal is to keep the primary public
API on the main repository object as stable as possible. Most users who rely on
documented methods like `g.commit`, `g.add`, and `g.status` should find the
transition to v5.0.0 straightforward.
>
> The breaking changes will primarily affect users who have been relying on the
internal g.lib accessor, which will be removed as part of this cleanup. For more
details, please see the "Impact on Users" section in [the redesign
> document](2_architecture_redesign.md).

# NYC street life asset brief

Original procedural PS1-style assets for Hopan's NYC district. No downloaded meshes or copied branding. Models use the existing world scale of 1.8 world units per grid cell. Geometry is deliberately readable from the following camera at a 240-pixel scene height.

The production package includes a slatted bench, trash can, dumpster, pizza cart, blue mailbox, traffic cone, manhole cover, newsstand, four-unit grind rail, four-unit wedge ramp, segmented roach and three distinct skateboard riders. Distinguishing structures take priority over microdetail.

All enemies and skate features face local -Z. The skater's Board is independent of RiderRoot. Named shoulder and hip pivots allow authored push, crouch, grind balance and ramp presentation. Roach leg and antenna pivots support a six-leg gait. Static prop geometry is eligible for the world's existing batching; articulated actor parts stay independent.

Rail top is y=.65. The truck mesh underside is y=.045, measured from its center at .08 and .07 height. A .605 actor-root offset places that underside on the rail. Ramp surface rises from zero at z=+2 to .70 at z=-2. The player is still a ground-plane actor; ramp elevation belongs to skating enemy presentation.

This is stylized fiction rather than a survey of New York street furniture. Engine source and actual rendered review are required before visual approval. Runtime collision and movement are owned by the gameplay integration, not this asset factory.

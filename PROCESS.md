# Automation process

This document describes the automation process step-by-step.

1.  Import market data into reference model
    1.  Merge model elements from master model
    2.  Update user-defined-attributes
        1.  Generate JAR
        2.  Update database
    3.  Import observations
2.  Import production model
    1.  Create bank model
    2.  Import master model elements
    3.  Update user-defined-attributes
        1.  Generate JAR
        2.  Update database
    4.  Import contracts
3.  Run solves
    1.  Run static analysis `LIQ Static Analysis`
4.  Historisation
    1.  Run static solve `Historization` on production model
    2.  Run rollup solve `Daily rollup` on historisation model
5.  Maintenance
    1.  Run clean-roll-up solve `Daily purge` on historisation model
    2.  Delete models older than `n` days

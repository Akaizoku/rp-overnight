# Automation process

This document describes the automation process step-by-step.

1.  Import market data into reference model
    1.  Merge model elements from master model
    2.  Import calendars
    3.  Import observations
2.  Import production model
    1.  Create bank model
    2.  Import master model elements
    3.  Import contracts
    4.  Import new production
3.  Run solves and export results (`[res].[P_Load_Model_Master]`)
    1.  Run static analyses
        1.  `Regulatory EVE`
        2.  `Fixing Gap`
        3.  `Cash Flow Calculation`
        4.  `DoE`
        5.  `Fixing Gap Portfolio Level`
    2.  Run dynamic analyses
        1.  `NII`
        2.  `Liquidity Projection`
        3.  `Survival Horizon`
        4.  `Dynamic LCR`
        5.  `Dynamic NSFR`
        6.  `Dynamic LR`
4.  Historisation
    1.  Run static solve `Historization` on production model
    2.  Run rollup solve on historisation model
        1.  `Daily rollup`
        2.  `Monthly rollup`
        3.  `Monthly_NII_Rollup_<MM>_<YYYY>`
5.  Maintenance
    1.  Run clean-roll-up solve `Daily purge` on historisation model
    2.  Delete models older than `n` days
    3.  Send end-of-process emails (`[res].[P_Send_Validation_Mail]`)

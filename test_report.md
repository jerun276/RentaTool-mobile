# RentaTool Mobile Test Report

The previous version of this report contained stale totals and a screenshot path that is no longer present. The corrected mobile results, rerun commands, and screenshot evidence index are maintained in [`RentaTool/nfr-testing/FLUTTER_TEST_REPORT.md`](../RentaTool/nfr-testing/FLUTTER_TEST_REPORT.md).

Use the raw logs in this repository when checking a result:

- `unit_test_output.txt` — latest saved unit/widget run, including the three test-file load errors.
- `e2e_output_fixed.txt` — saved full-app Flutter web E2E run, 4 passed and 1 login failure.
- `nfr_mobile_m02_output.txt` — historical Android viewport-fit test pass.
- `nfr_mobile_output.txt` — latest M01 device retest attempt, blocked because no Android device was connected.
- `integration_test_output_flutter_xplat01.txt` — single catalog API integration test pass.
- `screenshots/2026-10-06_*/` — separate Flutter UI captures; they are not embedded in the testing guide PDF.

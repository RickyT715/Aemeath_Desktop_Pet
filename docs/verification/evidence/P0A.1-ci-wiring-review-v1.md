Verdict: **GO**

C/I/M census: **0 / 0 / 0**

独立静态终审通过：

- P0A.1 contract exact：`minimum=8`、`includedInJobMinimum=false`、独立 sink `preservation-specification-tests.log`（`.github/ci/required-checks.json:102-154`）。
- Parent floor 保持 24，仅 D0.3 的 24 计入；D0.5 Ubuntu 45 与 P0A.1 8 均强制但不聚合，不能互相补偿。
- Workflow 恰有一次 P0A.1 command→`Tee-Object` retained pipeline，位于 blocking `verification-contracts` job，artifact `always()` 上传并保留 90 天（`.github/workflows/ci.yml:122-177`）。
- Runtime gate 对每个 result 独立要求：
  - marker 恰一次且位于声明 sink；
  - strict six-field JSON shape；
  - exact lowercase source SHA；
  - actual ≥ own minimum；
  - failed/skipped 均为 0；
  - 只有 `included=true` 才计入 parent total。
  证据：`tools/ci/CiDeliveryContract.psm1:89-254`。
- Static gate 验证 result shape、portable evidence path、reachable exact Tee sink、positive integer minimum、boolean inclusion 与 included-total equality（`tools/ci/Verify-CiWorkflow.ps1:718-862`）。
- False-green controls充分：
  - excluded D0.5/P0A.1 marker 缺失仍失败（`Test-CiDelivery.ps1:1009-1040`）；
  - dead/after-return pipeline、错 sink、无 retained file 均拒绝；
  - exact producer source及参数受 AST gate。
- 独立 AST census：**9 个 live producers**，逐 ResultId/ActualDiscovery exact；P0A.1 producer唯一且使用 `$probeCount`。`Test-CiDelivery.ps1:1668-1742` 的 expected census 与当前 AST 完全一致。
- P0A.1 integration assertion另行固定 result/sink/minimum/inclusion/minimumBytes（`Test-CiDelivery.ps1:1746-1759`）。
- D0.3 未漂移：producer仍 `$discoveredProbes`，自身 frozen floor 24 后才写 marker（`Test-VerificationContracts.ps1:1342-1352`）。
- D0.5 未漂移：
  - Ubuntu 45、excluded；
  - Windows 45 + package 15，parent 60；
  - 三个 producer及既有 route/变量 exact。
- `Wait-ForCi` 保留所有 component records，不丢弃 excluded P0A.1，实际 gate重新调用同一 discovery/result validator（`Wait-ForCi.ps1:15-49,52-110,249-292`）。
- README 对 8 probes、7 mutations、CI exact `SOURCE_SHA`、独立 retained sink及不计入 D0.3 floor的描述准确（`docs/verification/README.md:91-98`）。
- PS5 parser 对八个相关 PowerShell sources均为 0 errors；所用 API/语法兼容 Windows PowerShell 5.1 与 Ubuntu/Windows pwsh。
- False-block检查：verification checkout为 exact `SOURCE_SHA` 且 `fetch-depth:0`；P0 validator/module identities仍为 `a096afd7...` / `85cd1c77...`，不会因 wiring 文件本身变化触发 authority drift。
- 产品源码未变化：两个 frozen roots独立重算仍为：
  - 94 / 6288961 / `28d3d397...`
  - 46 / 111640 / `98a46adb...`

这是 **CI wiring 静态 GO**，不是实际 CI 已运行或通过的宣称。未运行 P0A validator、项目、Git 或网络，未修改文件。

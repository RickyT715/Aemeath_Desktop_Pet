[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$originalSpecificationPath = Join-Path $repositoryRoot "docs/verification/preservation-spec-v1.yml"
$predecessorSpecificationPath = Join-Path $repositoryRoot "docs/verification/preservation-spec-v4.yml"
$specificationRelativePath = "docs/verification/preservation-spec-v5.yml"
$specificationPath = Join-Path $repositoryRoot $specificationRelativePath
$manifestPath = Join-Path $repositoryRoot "docs/verification/manifests/P0A.1-v9.yml"
$v1InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v1.json"
$v2InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v2.json"
$v3InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v3.json"
$v4InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v4.json"
$v5ReplacementInvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v5-v2.json"
$v6InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v6.json"
$v7InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v7.json"
$v8InvalidationPath = Join-Path $repositoryRoot "docs/verification/invalidations/P0A.1-v8.json"
$traceabilityPath = Join-Path $repositoryRoot "docs/verification/traceability-v2.yml"
$predecessorTraceabilityPath = Join-Path $repositoryRoot "docs/verification/traceability-v1.yml"
$ciDeliveryContractModule = Join-Path $repositoryRoot "tools/ci/CiDeliveryContract.psm1"

$frozenManifestSha256 = "7e7d8c298b91f78479cb0dfc8a028e02d5f84785fd3d3768eb88e591c78a284d"
$invalidatedV1ManifestSha256 = "2c373ca1671c65cd7c4bed70af3aa10de08df0f9450ed8b2d7c4d2eeb1c25dbd"
$invalidatedV2ManifestSha256 = "60ae0b97ae95444b76ad064428801ed6988f7b2fcbdd5bccdfd69b5582d83d4e"
$invalidatedV3ManifestSha256 = "70e3247afb5fe77009221148a28fd5a2d1f16117e75416612fea9ce6a657bc29"
$invalidatedV4ManifestSha256 = "f6b06092f7070c8c9ef8a02c7465e9397adafc3189cf150b779fafd022b51609"
$invalidatedV5ManifestSha256 = "17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91"
$invalidatedV6ManifestSha256 = "e7afa6554e2eda77aa471eade20db990044509c01978f4944f5c0af56eb00f40"
$invalidatedV7ManifestSha256 = "6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef"
$invalidatedV8ManifestSha256 = "7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0"
$frozenV1InvalidationRecordSha256 = "cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221"
$frozenV2InvalidationRecordSha256 = "881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7"
$frozenV3InvalidationRecordSha256 = "e5c1add435b63e227a82837fd837b72d2f7c2df935cee5e6127b7e8ac9b71a10"
$frozenV4InvalidationRecordSha256 = "de56c2b3c183df68b2a3d4f27f250c20ef158a39dc46180cca3bddbcd8078724"
$frozenV5ReplacementInvalidationRecordSha256 = "e7d8b029224cff5968c81f3214f02dd9da2fa6de0e9527140df4152684907e93"
$frozenV6InvalidationRecordSha256 = "db7dfe0ac65cc8bcd722219e6652d3fb1bdc29901def38c46671fd9d92de74f0"
$frozenV7InvalidationRecordSha256 = "34ef8d158d82645e6feeefb9d20a6f9df4a9a195ebc288fba15de302669a7a1d"
$frozenV8InvalidationRecordSha256 = "97bea8753719a798cde630f2b8e3cab7adcd28213ef180728c3abae73a6574bf"
$frozenBaselineSha = "43f9c288f843f7620ffee5eee3504f52875f4774"
$frozenTraceabilitySha256 = "28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415"
$frozenPredecessorTraceabilitySha256 = "939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55"
$frozenTraceabilityBaselineSha = "a6c15496cf2893a24e560c01ef4e598a635859cc"
$frozenCurrentRequirementsOriginSha = "c2e3dbfd5e90bb40ea5006b702bbbc32d24a1ae7"
$frozenDispositionRecordsSha256 = "fdd77a96813a3d8d5270e47a803486cac64eff33e2f8426d97f1200240423f7b"
$frozenSpecificationSha256 = "123df163b9cfb23c7fe17b133a32757c90424bafc499aa1b089db24628c2c4c9"
$frozenPredecessorSpecificationSha256 = "874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3"
$frozenOriginalSpecificationSha256 = "9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d"
$cleanReviewEvidencePath = "docs/verification/evidence/P0A.1-clean-room-review-v7.md"
$expectedProductionRoots = [ordered]@{
    "src/AemeathDesktopPet" = [PSCustomObject]@{
        FileCount = 94
        Sha256 = "28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb"
    }
    "python-backend/aemeath_agent" = [PSCustomObject]@{
        FileCount = 46
        Sha256 = "98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae"
    }
}
$expectedFixtureArtifacts = [ordered]@{
    "P0A1-DATA-V5" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/data-v5.json"
        Sha256 = "4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0"
        SchemaVersion = 5
        Collection = "records"
        Count = 17
        BoundaryIds = @(
            "PB-001", "PB-003", "PB-004", "PB-005", "PB-006", "PB-007", "PB-008",
            "PB-009", "PB-010", "PB-011", "PB-012", "PB-013", "PB-014", "PB-016", "PB-017"
        )
    }
    "P0A1-ORACLES-V1" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/oracles-v1.json"
        Sha256 = "4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d"
        SchemaVersion = 1
        Collection = "oracles"
        Count = 28
        BoundaryIds = @(
            "PB-002", "PB-003", "PB-004", "PB-005", "PB-007", "PB-008", "PB-009",
            "PB-011", "PB-012", "PB-014", "PB-015", "PB-016", "PB-018"
        )
    }
    "P0A1-PROTOCOL-V3" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/protocol-v3.json"
        Sha256 = "cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565"
        SchemaVersion = 3
        Collection = "contracts"
        Count = 15
        BoundaryIds = @(
            "PB-005", "PB-006", "PB-007", "PB-011", "PB-012", "PB-013", "PB-014",
            "PB-015", "PB-016"
        )
    }
    "P0A1-RESOURCES-V1" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/resources-v1.json"
        Sha256 = "63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8"
        SchemaVersion = 1
        Collection = "resources"
        Count = 11
        BoundaryIds = @("PB-002", "PB-004", "PB-017", "PB-018")
    }
}
$expectedDataRecordIds = @(
    "DATA-CONFIG-DEFAULTS",
    "DATA-CONFIG-POSITION-RESTART",
    "DATA-STATS-BASELINE",
    "DATA-MESSAGES-TURN",
    "DATA-CORE-MEMORY",
    "DATA-PROCEDURAL-MEMORY",
    "DATA-OBSERVATION-BUFFER",
    "DATA-STARTUP-RUN-REGISTRY",
    "DATA-AGENT-CHECKPOINT",
    "DATA-PYTHON-MEMORY-STORE",
    "DATA-PYTHON-MEMORY-BLOCKS",
    "DATA-CHROMA",
    "DATA-TODO",
    "DATA-ACTIVITY-SQLITE-READONLY",
    "DATA-SIDECAR-ENVFILE-READONLY",
    "DATA-MUSIC-LIBRARY-READONLY",
    "DATA-RAG-SOURCE-FILE-OR-DIRECTORY-READONLY"
)
$expectedPersistedDataTargetIds = @(
    "DATA-CONFIG",
    "DATA-STATS",
    "DATA-MESSAGES",
    "DATA-CORE-MEMORY",
    "DATA-PROCEDURAL-MEMORY",
    "DATA-OBSERVATION-BUFFER",
    "DATA-STARTUP-RUN-REGISTRY",
    "DATA-AGENT-CHECKPOINT",
    "DATA-PYTHON-MEMORY-STORE",
    "DATA-PYTHON-MEMORY-BLOCKS",
    "DATA-CHROMA",
    "DATA-TODO",
    "DATA-ACTIVITY-SQLITE",
    "DATA-SIDECAR-ENVFILE",
    "DATA-MUSIC-LIBRARY",
    "DATA-RAG-SOURCE-DOCUMENTS"
)
$expectedApplicationOwnedTargetIds = @(
    "DATA-CONFIG",
    "DATA-STATS",
    "DATA-MESSAGES",
    "DATA-CORE-MEMORY",
    "DATA-PROCEDURAL-MEMORY",
    "DATA-OBSERVATION-BUFFER",
    "DATA-STARTUP-RUN-REGISTRY",
    "DATA-AGENT-CHECKPOINT",
    "DATA-PYTHON-MEMORY-STORE",
    "DATA-PYTHON-MEMORY-BLOCKS",
    "DATA-CHROMA",
    "DATA-TODO"
)
$expectedExternalReadOnlyTargetIds = @(
    "DATA-ACTIVITY-SQLITE",
    "DATA-SIDECAR-ENVFILE",
    "DATA-MUSIC-LIBRARY",
    "DATA-RAG-SOURCE-DOCUMENTS"
)
$expectedCurrentWritableTargetIds = @(
    "DATA-CONFIG",
    "DATA-STATS",
    "DATA-MESSAGES",
    "DATA-OBSERVATION-BUFFER",
    "DATA-STARTUP-RUN-REGISTRY",
    "DATA-AGENT-CHECKPOINT",
    "DATA-PYTHON-MEMORY-STORE",
    "DATA-PYTHON-MEMORY-BLOCKS",
    "DATA-CHROMA",
    "DATA-TODO"
)
$expectedLatentWritableTargetIds = @("DATA-CORE-MEMORY", "DATA-PROCEDURAL-MEMORY")
$expectedPersistedDataCensus = [ordered]@{
    recordCount = 17
    atomicTargetCount = 16
    appOwnedTargetCount = 12
    externalReadOnlyTargetCount = 4
    currentProductionWritableTargetCount = 10
    latentWritableCurrentlyReadOnlyTargetCount = 2
    v1RawPayloadByteMatchCount = 7
}
$expectedDataFixturePredecessor = [PSCustomObject]@{
    fixtureId = "P0A1-DATA-V4"
    path = "tests/fixtures/preservation/v1/data-v4.json"
    sha256 = "8b4d03ff5cb535a70660810870254d1e84d70381dfe8749f208416c3e134ea3b"
    recordCount = 17
    atomicTargetCount = 16
}
$expectedDataFixtureLineage = [ordered]@{
    "P0A1-DATA-V1" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/data-v1.json"
        Sha256 = "fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa"
        RecordCount = 7
    }
    "P0A1-DATA-V2" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/data-v2.json"
        Sha256 = "c1a18b2acd22a07568425567291a34bd43a0df839276d17258162d3da98fb315"
        RecordCount = 17
    }
    "P0A1-DATA-V3" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/data-v3.json"
        Sha256 = "a7ce95ef2124e517f5b9433cadfbecb6e08d1129d46538d3a4e5b6f2e6b18bbd"
        RecordCount = 17
    }
    "P0A1-DATA-V4" = [PSCustomObject]@{
        Path = "tests/fixtures/preservation/v1/data-v4.json"
        Sha256 = "8b4d03ff5cb535a70660810870254d1e84d70381dfe8749f208416c3e134ea3b"
        RecordCount = 17
    }
}
$expectedFixedInputAuthorities = [ordered]@{
    "docs/verification/preservation-spec-v1.yml" = [PSCustomObject]@{
        Sha256 = "9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/preservation-spec-v2.yml" = [PSCustomObject]@{
        Sha256 = "44a256a79cfb6b4c127aa79a7ae2f0c89b8f94a487e75a71797460bf0dcd4cd5"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/preservation-spec-v3.yml" = [PSCustomObject]@{
        Sha256 = "c0c4b90e9d65a46e6e297d928cbe805e802ba86b265cfdb46cb6766d76078f4f"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/preservation-spec-v4.yml" = [PSCustomObject]@{
        Sha256 = "874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/preservation-spec-v5.yml" = [PSCustomObject]@{
        Sha256 = "123df163b9cfb23c7fe17b133a32757c90424bafc499aa1b089db24628c2c4c9"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/manifests/P0A.1-v5.yml" = [PSCustomObject]@{
        Sha256 = "17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/manifests/P0A.1-v6.yml" = [PSCustomObject]@{
        Sha256 = "e7afa6554e2eda77aa471eade20db990044509c01978f4944f5c0af56eb00f40"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/manifests/P0A.1-v7.yml" = [PSCustomObject]@{
        Sha256 = "6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/manifests/P0A.1-v8.yml" = [PSCustomObject]@{
        Sha256 = "7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/manifests/P0A.1-v9.yml" = [PSCustomObject]@{
        Sha256 = "7e7d8c298b91f78479cb0dfc8a028e02d5f84785fd3d3768eb88e591c78a284d"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v1.json" = [PSCustomObject]@{
        Sha256 = "cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v2.json" = [PSCustomObject]@{
        Sha256 = "881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v3.json" = [PSCustomObject]@{
        Sha256 = "e5c1add435b63e227a82837fd837b72d2f7c2df935cee5e6127b7e8ac9b71a10"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v4.json" = [PSCustomObject]@{
        Sha256 = "de56c2b3c183df68b2a3d4f27f250c20ef158a39dc46180cca3bddbcd8078724"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v5.json" = [PSCustomObject]@{
        Sha256 = "65d7246b05f6d767458796bcea6d855b4db47f2793de0dc935ad3bb64d491d9b"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v5-v2.json" = [PSCustomObject]@{
        Sha256 = "e7d8b029224cff5968c81f3214f02dd9da2fa6de0e9527140df4152684907e93"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v6.json" = [PSCustomObject]@{
        Sha256 = "db7dfe0ac65cc8bcd722219e6652d3fb1bdc29901def38c46671fd9d92de74f0"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v7.json" = [PSCustomObject]@{
        Sha256 = "34ef8d158d82645e6feeefb9d20a6f9df4a9a195ebc288fba15de302669a7a1d"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/invalidations/P0A.1-v8.json" = [PSCustomObject]@{
        Sha256 = "97bea8753719a798cde630f2b8e3cab7adcd28213ef180728c3abae73a6574bf"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/evidence/P0A.1-clean-room-review-v5.md" = [PSCustomObject]@{
        Sha256 = "1be93b14dcc551025389b54c2cecd223cd31324f8ba57f7cd7cba6a539268074"
        Kind = "strict-text"
        NormalizedTextSha256 = $null
    }
    "docs/verification/evidence/P0A.1-clean-room-review-v6.md" = [PSCustomObject]@{
        Sha256 = "1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476"
        Kind = "strict-text"
        NormalizedTextSha256 = $null
    }
    "docs/verification/evidence/P0A.1-preservation-spec-v4-green-v1.md" = [PSCustomObject]@{
        Sha256 = "48cf0260ed05150919cc059685abb9482878b05611c8c95b27efcd291063adab"
        Kind = "strict-text"
        NormalizedTextSha256 = $null
    }
    "docs/verification/traceability-v2.yml" = [PSCustomObject]@{
        Sha256 = "28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "docs/verification/traceability-v1.yml" = [PSCustomObject]@{
        Sha256 = "939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/data-v1.json" = [PSCustomObject]@{
        Sha256 = "fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/data-v2.json" = [PSCustomObject]@{
        Sha256 = "c1a18b2acd22a07568425567291a34bd43a0df839276d17258162d3da98fb315"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/data-v3.json" = [PSCustomObject]@{
        Sha256 = "a7ce95ef2124e517f5b9433cadfbecb6e08d1129d46538d3a4e5b6f2e6b18bbd"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/data-v4.json" = [PSCustomObject]@{
        Sha256 = "8b4d03ff5cb535a70660810870254d1e84d70381dfe8749f208416c3e134ea3b"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/data-v5.json" = [PSCustomObject]@{
        Sha256 = "4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/protocol-v1.json" = [PSCustomObject]@{
        Sha256 = "95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/protocol-v2.json" = [PSCustomObject]@{
        Sha256 = "ec2ea43cf0d06ef75e7b0334b432464fca71b9198814287e2bf33bf8e026a602"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/protocol-v3.json" = [PSCustomObject]@{
        Sha256 = "cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/oracles-v1.json" = [PSCustomObject]@{
        Sha256 = "4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tests/fixtures/preservation/v1/resources-v1.json" = [PSCustomObject]@{
        Sha256 = "63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
    "tools/ci/CiDeliveryContract.psm1" = [PSCustomObject]@{
        Sha256 = "85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3"
        Kind = "strict-text"
        NormalizedTextSha256 = $null
    }
    "docs/verification/manifests/D0.4-v3.yml" = [PSCustomObject]@{
        Sha256 = "d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e"
        Kind = "strict-json"
        NormalizedTextSha256 = "3747f8520497b65544ef0cd1bb386b8e72866284001da408de111f454f0d614a"
    }
    "docs/verification/environments/D0.4-readiness-v1.json" = [PSCustomObject]@{
        Sha256 = "aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc"
        Kind = "strict-json"
        NormalizedTextSha256 = $null
    }
}
$expectedLaneIds = @(
    "V-UNIT",
    "V-COMPONENT",
    "V-CONTRACT",
    "V-WPF",
    "V-UIA",
    "V-FIXTURE-E2E",
    "V-REAL-E2E",
    "V-SECURITY",
    "V-ACCESS",
    "V-PERF",
    "V-PACKAGE",
    "V-STATIC",
    "V-MANUAL-WIN",
    "V-LEGACY"
)
$expectedBoundaryIds = @(1..18 | ForEach-Object { "PB-{0:D3}" -f $_ })
$expectedManifestRequirementIds = @(
    "CURRENT:AC-FUT-001",
    "CURRENT:AC-FUT-002",
    "CURRENT:AC-FUT-003",
    "CURRENT:FR-FUT-001",
    "CURRENT:FR-FUT-002",
    "CURRENT:FR-FUT-003",
    "CURRENT:LOC-ASSETS",
    "CURRENT:LOC-GAPS",
    "CURRENT:LOC-INTENT",
    "CURRENT:LOC-PORTS",
    "CURRENT:LOC-PRIVACY",
    "CURRENT:LOC-RUNTIME",
    "CURRENT:LOC-SCOPE",
    "CURRENT:LOC-STATUS",
    "CURRENT:LOC-STORAGE",
    "CURRENT:LOC-TRANSMISSION",
    "CURRENT:LOC-VERIFY",
    "PRD:AC-FR-021-01",
    "PRD:AC-FR-021-02",
    "PRD:AC-FR-021-03",
    "PRD:AC-FR-021-05",
    "PRD:AC-FR-021-09",
    "PRD:AC-FR-021-10",
    "PRD:AC-FR-021-12",
    "PRD:AC-FR-024-02",
    "PRD:GATE-0-01",
    "PRD:GATE-0-02",
    "PRD:GATE-0-04",
    "PRD:GATE-0-05",
    "PRD:GATE-0-06",
    "PRD:NFR-JA-005",
    "PRD:NFR-JA-005-01",
    "PRD:NFR-JA-005-02",
    "PRD:RISK-010"
)
$expectedGapIds = @(
    "GAP-PET-THROW-RELEASE",
    "GAP-PET-EDGE-SUBSCRIPTIONS",
    "GAP-PAPER-PLANE-RENDERER",
    "GAP-FULLSCREEN-PET-POLICY",
    "GAP-KEYBOARD-COMPANION-SURFACE",
    "GAP-STATE-CAT-ASSETS",
    "GAP-SIDECAR-CONFIGURED-PORT",
    "GAP-SIDECAR-RELEASE-PACKAGE",
    "GAP-AGENT-SCREENSHOT-SHAPE",
    "GAP-AGENT-RESPONSE-FIELD",
    "GAP-STT-CONTRACT",
    "GAP-RAG-LIVE-CONFIG",
    "GAP-MCP-LIFECYCLE",
    "GAP-MEMORY-AUTHORITIES",
    "GAP-MEMORY-CONTROL-UI",
    "GAP-PLAINTEXT-SECRETS",
    "GAP-LOOPBACK-AUTH",
    "GAP-WPF-BRIDGE-ROUTE-DRIFT",
    "GAP-UI-AUTOMATION-SEMANTICS",
    "GAP-REMINDER-LOOP-MISSING",
    "GAP-DAILY-BRIEF-MISSING",
    "GAP-AGENT-SSE-FRAMING",
    "GAP-AGENT-SSE-TOOL-CALL",
    "GAP-AGENT-SSE-ERROR-VISIBILITY",
    "GAP-CHAT-TIER-FAILOVER",
    "GAP-VISION-SAVED-PRIVACY-CONTROLS",
    "GAP-RUNTIME-CONFIG-SYNC-NOOP",
    "GAP-SIDECAR-ENV-PREFIX-DRIFT",
    "GAP-USER-BLOCK-STARTUP-SNAPSHOT",
    "GAP-PROCEDURAL-LEARNING-CONSOLIDATION",
    "GAP-MEMORY-FORGET-TIME-RANGE",
    "GAP-MEMORY-DISTILLATION-FALSE-SUCCESS",
    "GAP-MINIGAMES-MISSING",
    "GAP-INTERACTION-SOUNDS-MISSING",
    "GAP-CHECKPOINT-SQLITE-DEPENDENCY-MANIFEST"
)
$expectedGapContracts = [ordered]@{
    "GAP-PET-THROW-RELEASE" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-PET-004")
        BoundaryIds = @("PB-002", "PB-003")
        LaterRedStep = "P4.5a"
    }
    "GAP-PET-EDGE-SUBSCRIPTIONS" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-PET-007")
        BoundaryIds = @("PB-002", "PB-003", "PB-004", "PB-018")
        LaterRedStep = "P4.5b"
    }
    "GAP-PAPER-PLANE-RENDERER" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-PET-008")
        BoundaryIds = @("PB-004", "PB-018")
        LaterRedStep = "P4.5c"
    }
    "GAP-FULLSCREEN-PET-POLICY" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-PET-010")
        BoundaryIds = @("PB-003", "PB-007", "PB-018")
        LaterRedStep = "P4.5d"
    }
    "GAP-KEYBOARD-COMPANION-SURFACE" = [PSCustomObject]@{
        RequirementIds = @("PRD:AC-FR-017-01")
        BoundaryIds = @("PB-003", "PB-005", "PB-008", "PB-018")
        LaterRedStep = "P4.5e"
    }
    "GAP-STATE-CAT-ASSETS" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-PET-006", "CURRENT:FR-FUT-002")
        BoundaryIds = @("PB-004", "PB-018")
        LaterRedStep = "UNSCHEDULED-PENDING-APPROVAL:APP-008"
    }
    "GAP-SIDECAR-CONFIGURED-PORT" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-002", "CURRENT:FR-AI-005")
        BoundaryIds = @("PB-011", "PB-012", "PB-016")
        LaterRedStep = "P2.2"
    }
    "GAP-SIDECAR-RELEASE-PACKAGE" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-002", "CURRENT:FR-AI-005")
        BoundaryIds = @("PB-011", "PB-017", "PB-018")
        LaterRedStep = "P2.5"
    }
    "GAP-AGENT-SCREENSHOT-SHAPE" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:LOC-TRANSMISSION")
        BoundaryIds = @("PB-007", "PB-012", "PB-016")
        LaterRedStep = "P2.1"
    }
    "GAP-AGENT-RESPONSE-FIELD" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-002")
        BoundaryIds = @("PB-005", "PB-012")
        LaterRedStep = "P2.1"
    }
    "GAP-STT-CONTRACT" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-VOICE-003")
        BoundaryIds = @("PB-006", "PB-012", "PB-016")
        LaterRedStep = "P9.1b"
    }
    "GAP-RAG-LIVE-CONFIG" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-AI-006", "CURRENT:FR-AI-007")
        BoundaryIds = @("PB-013")
        LaterRedStep = "P9.2"
    }
    "GAP-MCP-LIFECYCLE" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-AI-008")
        BoundaryIds = @("PB-015", "PB-016", "PB-017")
        LaterRedStep = "P10.1"
    }
    "GAP-MEMORY-AUTHORITIES" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-MEM-001", "CURRENT:FR-MEM-003", "CURRENT:FR-MEM-004")
        BoundaryIds = @("PB-005", "PB-014", "PB-016")
        LaterRedStep = "P7.2/P7.5"
    }
    "GAP-MEMORY-CONTROL-UI" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-MEM-006", "CURRENT:PR-005")
        BoundaryIds = @("PB-014", "PB-016", "PB-018")
        LaterRedStep = "P7.4"
    }
    "GAP-PLAINTEXT-SECRETS" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:PR-004")
        BoundaryIds = @("PB-008", "PB-016", "PB-018")
        LaterRedStep = "P1.4/P0B.3c"
    }
    "GAP-LOOPBACK-AUTH" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:PR-006")
        BoundaryIds = @("PB-011", "PB-012", "PB-015", "PB-016")
        LaterRedStep = "P2.2/P2.4"
    }
    "GAP-WPF-BRIDGE-ROUTE-DRIFT" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-003", "CURRENT:FR-AI-006")
        BoundaryIds = @("PB-012", "PB-016")
        LaterRedStep = "P2.1/P2.4"
    }
    "GAP-UI-AUTOMATION-SEMANTICS" = [PSCustomObject]@{
        RequirementIds = @("PRD:AC-FR-017-01", "PRD:AC-FR-017-02", "PRD:AC-FR-017-03")
        BoundaryIds = @("PB-003", "PB-004", "PB-006", "PB-008", "PB-016", "PB-018")
        LaterRedStep = "P0B.3"
    }
    "GAP-REMINDER-LOOP-MISSING" = [PSCustomObject]@{
        RequirementIds = @(
            "PRD:AC-FR-004-01", "PRD:AC-FR-004-02", "PRD:AC-FR-004-03",
            "PRD:AC-FR-004-04", "PRD:AC-FR-004-05"
        )
        BoundaryIds = @("PB-014", "PB-018")
        LaterRedStep = "P5.1/P5.2"
    }
    "GAP-DAILY-BRIEF-MISSING" = [PSCustomObject]@{
        RequirementIds = @(
            "PRD:AC-FR-003-01", "PRD:AC-FR-003-02", "PRD:AC-FR-003-03",
            "PRD:AC-FR-003-04", "PRD:AC-FR-003-05"
        )
        BoundaryIds = @("PB-013", "PB-014", "PB-018")
        LaterRedStep = "P5.3/P5.4"
    }
    "GAP-AGENT-SSE-FRAMING" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-002", "CURRENT:FR-AI-001", "CURRENT:LOC-RUNTIME")
        BoundaryIds = @("PB-005", "PB-011", "PB-012")
        LaterRedStep = "P0B.1d/P2.1"
        Statement = "The sidecar passes already-framed SSE text to EventSourceResponse while sse-starlette is constrained only as >=2.0.0; formatter behavior is unpinned, exact wire bytes are not frozen, and compatibility remains unqualified."
    }
    "GAP-AGENT-SSE-TOOL-CALL" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-002", "CURRENT:FR-AI-006")
        BoundaryIds = @("PB-005", "PB-012", "PB-013")
        LaterRedStep = "P2.1"
        Statement = "The sidecar places the streamed tool name in content while the desktop expects data.name; transport framing is separately unqualified, so this static shape mismatch is preserved without asserting a wire outcome."
    }
    "GAP-AGENT-SSE-ERROR-VISIBILITY" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-002", "CURRENT:AR-004", "CURRENT:FR-AI-001")
        BoundaryIds = @("PB-005", "PB-011", "PB-012")
        LaterRedStep = "P2.1"
        Statement = "The sidecar emits an error event type while the desktop has no error-event case; transport framing is separately unqualified, so this static visibility gap is preserved without asserting whether the event reaches the consumer."
    }
    "GAP-CHAT-TIER-FAILOVER" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:AR-004", "PRD:AC-FR-014-02")
        BoundaryIds = @("PB-005", "PB-011")
        LaterRedStep = "P2.3/P3.3"
    }
    "GAP-VISION-SAVED-PRIVACY-CONTROLS" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-VISION-004")
        BoundaryIds = @("PB-007", "PB-016")
        LaterRedStep = "P6.3"
    }
    "GAP-RUNTIME-CONFIG-SYNC-NOOP" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:LOC-GAPS")
        BoundaryIds = @("PB-008", "PB-011", "PB-012", "PB-013", "PB-016")
        LaterRedStep = "P2.1/P2.2"
    }
    "GAP-SIDECAR-ENV-PREFIX-DRIFT" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-AI-005", "CURRENT:FR-AI-006", "CURRENT:LOC-GAPS")
        BoundaryIds = @("PB-008", "PB-011", "PB-012", "PB-013", "PB-016")
        LaterRedStep = "P2.2"
    }
    "GAP-USER-BLOCK-STARTUP-SNAPSHOT" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-MEM-005")
        BoundaryIds = @("PB-009", "PB-014", "PB-016")
        LaterRedStep = "P7.3"
    }
    "GAP-PROCEDURAL-LEARNING-CONSOLIDATION" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-MEM-001", "CURRENT:FR-MEM-007")
        BoundaryIds = @("PB-009", "PB-014", "PB-016")
        LaterRedStep = "P7.3"
    }
    "GAP-MEMORY-FORGET-TIME-RANGE" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-MEM-006", "CURRENT:PR-005")
        BoundaryIds = @("PB-009", "PB-014", "PB-016")
        LaterRedStep = "P7.2/P7.4"
    }
    "GAP-MEMORY-DISTILLATION-FALSE-SUCCESS" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-MEM-002")
        BoundaryIds = @("PB-007", "PB-009", "PB-014", "PB-016")
        LaterRedStep = "P7.3"
    }
    "GAP-MINIGAMES-MISSING" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-FUT-001")
        BoundaryIds = @("PB-002", "PB-004", "PB-018")
        LaterRedStep = "UNSCHEDULED-PENDING-APPROVAL:APP-007"
    }
    "GAP-INTERACTION-SOUNDS-MISSING" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-FUT-003")
        BoundaryIds = @("PB-002", "PB-004", "PB-018")
        LaterRedStep = "UNSCHEDULED-PENDING-APPROVAL:APP-009"
    }
    "GAP-CHECKPOINT-SQLITE-DEPENDENCY-MANIFEST" = [PSCustomObject]@{
        RequirementIds = @("CURRENT:FR-AI-005", "CURRENT:LOC-RUNTIME")
        BoundaryIds = @("PB-011", "PB-013", "PB-014", "PB-017")
        LaterRedStep = "P0B.1d"
        Statement = "The checkpointer imports langgraph.checkpoint.sqlite.aio, but python-backend/pyproject.toml does not declare langgraph-checkpoint-sqlite."
        SourceLocators = @(
            "python-backend/aemeath_agent/agent/checkpointer.py",
            "python-backend/pyproject.toml"
        )
    }
}
$expectedSpecialLaneBehaviors = [ordered]@{
    "V-WPF" = @(
        "PB-002", "PB-003", "PB-004", "PB-005", "PB-008", "PB-009",
        "PB-016", "PB-017", "PB-018"
    )
    "V-UIA" = @(
        "PB-001", "PB-002", "PB-003", "PB-004", "PB-005", "PB-007",
        "PB-008", "PB-016", "PB-017", "PB-018"
    )
    "V-ACCESS" = @(
        "PB-001", "PB-002", "PB-003", "PB-004", "PB-005", "PB-006", "PB-007",
        "PB-008", "PB-010", "PB-016", "PB-017", "PB-018"
    )
}
$expectedTraceRows = [ordered]@{
    "P0A.1-V-STATIC-STATIC-CONTRACT" = [PSCustomObject]@{
        OwnerStep = "P0A.1"
        Lane = "V-STATIC"
        RequirementIds = $expectedManifestRequirementIds
        BehaviorIds = $expectedBoundaryIds
    }
    "P0A.2-V-REAL-E2E-KEYBOARD-SURFACE" = [PSCustomObject]@{
        OwnerStep = "P0A.2"
        Lane = "V-REAL-E2E"
        RequirementIds = @(
            "CURRENT:AC-PET-005", "CURRENT:FR-PET-005", "PRD:AC-FR-021-07",
            "PRD:AC-FR-024-02", "PRD:GATE-0-03", "PRD:NFR-JA-005", "PRD:NFR-JA-005-05"
        )
        BehaviorIds = $expectedBoundaryIds
    }
    "P0A.2-V-REAL-E2E-PET-VISIBILITY" = [PSCustomObject]@{
        OwnerStep = "P0A.2"
        Lane = "V-REAL-E2E"
        RequirementIds = @(
            "CURRENT:AC-PET-001", "CURRENT:FR-PET-001", "PRD:AC-FR-021-07",
            "PRD:AC-FR-024-02", "PRD:GATE-0-03", "PRD:NFR-JA-005", "PRD:NFR-JA-005-05"
        )
        BehaviorIds = $expectedBoundaryIds
    }
    "P2.3-V-CONTRACT-CONTRACT-COMPATIBILITY" = [PSCustomObject]@{
        OwnerStep = "P2.3"
        Lane = "V-CONTRACT"
        RequirementIds = @("CURRENT:AC-AR-004", "CURRENT:AR-004", "PRD:AC-FR-001-04", "PRD:AC-FR-014-04")
        BehaviorIds = @("PB-001", "PB-005", "PB-006", "PB-011", "PB-017", "PB-018")
    }
    "P3.3-V-CONTRACT-CONTRACT-COMPATIBILITY" = [PSCustomObject]@{
        OwnerStep = "P3.3"
        Lane = "V-CONTRACT"
        RequirementIds = @("PRD:AC-FR-002-02", "PRD:AC-FR-002-04", "PRD:AC-FR-014-02")
        BehaviorIds = @("PB-001", "PB-011", "PB-016", "PB-017")
    }
    "P3.3-V-SECURITY-SECURITY-CONTROLS" = [PSCustomObject]@{
        OwnerStep = "P3.3"
        Lane = "V-SECURITY"
        RequirementIds = @(
            "PRD:AC-FR-002-02", "PRD:AC-FR-002-04", "PRD:AC-FR-006-03",
            "PRD:AC-FR-007-04", "PRD:AC-FR-007-05", "PRD:AC-FR-007-06",
            "PRD:AC-FR-014-02", "PRD:AC-FR-020-02", "PRD:GATE-D-01",
            "PRD:NFR-JA-003", "PRD:NFR-JA-003-02", "PRD:NFR-JA-003-05"
        )
        BehaviorIds = @(
            "PB-001", "PB-002", "PB-004", "PB-009", "PB-011",
            "PB-013", "PB-015", "PB-016", "PB-017", "PB-018"
        )
    }
    "P4.5c-V-WPF-WPF-STATE" = [PSCustomObject]@{
        OwnerStep = "P4.5c"
        Lane = "V-WPF"
        RequirementIds = @("CURRENT:AC-PET-008", "CURRENT:FR-PET-008")
        BehaviorIds = @("PB-004", "PB-018")
    }
    "P4.5e-V-ACCESS-ACCESSIBILITY-JOURNEY" = [PSCustomObject]@{
        OwnerStep = "P4.5e"
        Lane = "V-ACCESS"
        RequirementIds = @("PRD:AC-FR-017-01")
        BehaviorIds = @("PB-003", "PB-005", "PB-008", "PB-018")
    }
    "P9.2-V-COMPONENT-COMPONENT-FLOW" = [PSCustomObject]@{
        OwnerStep = "P9.2"
        Lane = "V-COMPONENT"
        RequirementIds = @(
            "CURRENT:AC-AI-006", "CURRENT:FR-AI-006", "PRD:AC-FR-012-01",
            "PRD:AC-FR-012-02", "PRD:AC-FR-012-03", "PRD:AC-FR-012-04", "PRD:AC-FR-012-05"
        )
        BehaviorIds = @("PB-013", "PB-016")
    }
    "P9.2-V-FIXTURE-E2E-FIXTURE-JOURNEY" = [PSCustomObject]@{
        OwnerStep = "P9.2"
        Lane = "V-FIXTURE-E2E"
        RequirementIds = @(
            "CURRENT:AC-AI-007", "CURRENT:FR-AI-007", "PRD:AC-FR-012-01",
            "PRD:AC-FR-012-02", "PRD:AC-FR-012-03", "PRD:AC-FR-012-04", "PRD:AC-FR-012-05"
        )
        BehaviorIds = @("PB-013", "PB-016")
    }
    "P9.2-V-SECURITY-SECURITY-CONTROLS" = [PSCustomObject]@{
        OwnerStep = "P9.2"
        Lane = "V-SECURITY"
        RequirementIds = @("PRD:AC-FR-012-05")
        BehaviorIds = @("PB-013", "PB-016")
    }
    "P0A.6-V-WPF-WPF-STATE" = [PSCustomObject]@{
        OwnerStep = "P0A.6"
        Lane = "V-WPF"
        RequirementIds = @(
            "CURRENT:AC-PET-006", "CURRENT:AC-PET-008", "CURRENT:AC-PET-009",
            "CURRENT:AC-PET-013", "CURRENT:FR-PET-006", "CURRENT:FR-PET-008",
            "CURRENT:FR-PET-009", "CURRENT:FR-PET-013", "CURRENT:PR-004",
            "PRD:AC-FR-024-02", "PRD:GATE-0-03"
        )
        BehaviorIds = @(
            "PB-002", "PB-003", "PB-004", "PB-005", "PB-008", "PB-009",
            "PB-016", "PB-017", "PB-018"
        )
    }
    "P0A.6-V-UIA-UIA-JOURNEY" = [PSCustomObject]@{
        OwnerStep = "P0A.6"
        Lane = "V-UIA"
        RequirementIds = @("CURRENT:AC-PET-001", "CURRENT:FR-PET-001", "CURRENT:PR-002")
        BehaviorIds = @("PB-001", "PB-002", "PB-003", "PB-007", "PB-016", "PB-018")
    }
    "P0A.7-V-UIA-UIA-JOURNEY" = [PSCustomObject]@{
        OwnerStep = "P0A.7"
        Lane = "V-UIA"
        RequirementIds = @(
            "CURRENT:AC-PET-005", "CURRENT:FR-PET-005", "PRD:AC-FR-024-02",
            "PRD:GATE-0-03"
        )
        BehaviorIds = @("PB-003", "PB-004", "PB-005", "PB-008", "PB-016", "PB-017", "PB-018")
    }
    "P0A.6-V-ACCESS-ACCESSIBILITY-JOURNEY" = [PSCustomObject]@{
        OwnerStep = "P0A.6"
        Lane = "V-ACCESS"
        RequirementIds = @("PRD:AC-FR-024-02", "PRD:GATE-0-04")
        BehaviorIds = @(
            "PB-001", "PB-002", "PB-003", "PB-004", "PB-005", "PB-006",
            "PB-007", "PB-008", "PB-010", "PB-016", "PB-017", "PB-018"
        )
    }
}
$expectedSources = [ordered]@{
    "CURRENT:REQUIREMENTS" = [PSCustomObject]@{
        Path = "REQUIREMENTS.md"
        Revision = "c2e3dbfd5e90bb40ea5006b702bbbc32d24a1ae7"
        HashMode = "normalized-text"
        Sha256 = "94c8c95a75ca7f6f417e4b6358042ed727656cd58074213f878ddbaaeff37cbc"
    }
    "CURRENT:LOCATORS" = [PSCustomObject]@{
        Path = "docs/plans/20260722-jarvis-assistant-tdd-checklist.md"
        Revision = "a6c15496cf2893a24e560c01ef4e598a635859cc"
        HashMode = "normalized-checkbox-text"
        Sha256 = "0d20daf50ef166b78805f170972b517e1533a0b69afc274a44c8e0ef5628ad58"
    }
    "PRD:JARVIS" = [PSCustomObject]@{
        Path = "docs/prd/jarvis_assistant_prd.md"
        Revision = "a6c15496cf2893a24e560c01ef4e598a635859cc"
        HashMode = "normalized-text"
        Sha256 = "b2ee8dfaffdfa27e22f820f5bf7f6a065a360933a5c4b1789b4cd1ea27d791b2"
    }
    "DESIGN:JARVIS" = [PSCustomObject]@{
        Path = "docs/design/jarvis_assistant_design.md"
        Revision = "a6c15496cf2893a24e560c01ef4e598a635859cc"
        HashMode = "normalized-text"
        Sha256 = "f280cdbd89946d934888cd91ef2c7fafa0478126f58ec2e4365f7be23481f12b"
    }
    "UI:JARVIS" = [PSCustomObject]@{
        Path = "docs/ui-spec/jarvis_assistant_ui_spec.md"
        Revision = "a6c15496cf2893a24e560c01ef4e598a635859cc"
        HashMode = "normalized-text"
        Sha256 = "806d37aa63a719dda7de7446c2e6ff6bbc55243eb0ce6478d6464ad7ca68b1c1"
    }
    "ADR:VERIFICATION" = [PSCustomObject]@{
        Path = "docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md"
        Revision = "a6c15496cf2893a24e560c01ef4e598a635859cc"
        HashMode = "normalized-text"
        Sha256 = "21ac1e7df434b37d4a8fe596d8dcceab9f26eb386f5d77cf88b052473253f9e9"
    }
}
$expectedEnvironments = [ordered]@{
    "ENV-WINDOWS-LOCAL" = [PSCustomObject]@{
        Os = "Windows 11 x64 development environment"
        Status = "ready"
        CapabilityIds = @("LOCAL-WINDOWS-PS51")
        TargetSteps = @("P0A.1")
    }
    "ENV-GHA-UBUNTU" = [PSCustomObject]@{
        Os = "ubuntu-latest"
        Status = "ready"
        CapabilityIds = @("CAP-GHA-UBUNTU-EXACT-SHA", "CAP-CI-ARTIFACT-RETENTION")
        TargetSteps = @("P0A.1")
    }
    "ENV-GHA-WINDOWS" = [PSCustomObject]@{
        Os = "windows-latest"
        Status = "capability-observed-qualification-pending"
        CapabilityIds = @("CAP-GHA-WINDOWS-CAPABILITY-PROBE", "CAP-GHA-WINDOWS-RELEASE-BUILD")
        TargetSteps = @("P0A.2", "P0A.6", "P0A.7")
    }
    "ENV-INTERACTIVE-WIN10" = [PSCustomObject]@{
        Os = "Windows 10 x64 interactive worker"
        Status = "blocked-not-provisioned"
        CapabilityIds = @("CAP-INTERACTIVE-WIN10", "CAP-SELF-HOSTED-RUNNER-LABELS")
        TargetSteps = @("P0A.2", "P0A.8")
    }
    "ENV-INTERACTIVE-WIN11" = [PSCustomObject]@{
        Os = "Windows 11 x64 interactive worker"
        Status = "blocked-not-provisioned"
        CapabilityIds = @("CAP-INTERACTIVE-WIN11", "CAP-SELF-HOSTED-RUNNER-LABELS")
        TargetSteps = @("P0A.2", "P0A.7", "P0A.8")
    }
}
$expectedManifestEnvironments = [ordered]@{
    "ENV-WINDOWS-LOCAL" = [PSCustomObject]@{
        Os = "Windows 11 x64 development environment"
        Shell = "Windows PowerShell 5.1 plus pinned Python jsonschema fallback"
        Purpose = "Local RED/GREEN, byte/hash verification, and PowerShell 5.1 portability"
    }
    "ENV-GHA-UBUNTU" = [PSCustomObject]@{
        Os = "ubuntu-latest"
        Shell = "PowerShell 7.4+"
        Purpose = "Blocking exact-head-SHA preservation specification verification with retained evidence"
    }
    "ENV-GHA-WINDOWS" = [PSCustomObject]@{
        Os = "windows-latest"
        Shell = "PowerShell 7.4+"
        Purpose = "Disposable hosted Windows capability observation"
    }
    "ENV-INTERACTIVE-WIN10" = [PSCustomObject]@{
        Os = "Windows 10 x64 interactive worker"
        Shell = "PowerShell 7.4+"
        Purpose = "Later real desktop and assistive-technology evidence"
    }
    "ENV-INTERACTIVE-WIN11" = [PSCustomObject]@{
        Os = "Windows 11 x64 interactive worker"
        Shell = "PowerShell 7.4+"
        Purpose = "Later UIA, real desktop, and assistive-technology evidence"
    }
}
$expectedLegacyRoots = @("tests/AemeathDesktopPet.Tests", "python-backend/tests", ".superpowers")
$expectedForbiddenCategories = @(
    "legacy-test-helpers",
    "legacy-fixtures-and-snapshots",
    "generated-expected-values-and-assertions",
    "prior-test-results-and-evidence"
)
$expectedManifestRedOracle = "Clean-room review v6 is a frozen PASS with C=0, I=0, and M=0 at docs/verification/evidence/P0A.1-clean-room-review-v6.md, SHA-256 1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476. Local GREEN evidence is frozen at docs/verification/evidence/P0A.1-preservation-spec-v4-green-v1.md, SHA-256 48cf0260ed05150919cc059685abb9482878b05611c8c95b27efcd291063adab. CI source-identity integration remains BLOCK because the current validator incorrectly requires live Git HEAD to equal the historical baseline 43f9c288f843f7620ffee5eee3504f52875f4774, which necessarily fails after a successor commit. V9 authorizes an immutable successor that preserves the historical baseline and production-root digests, requires lowercase 40-hex live HEAD, requires a non-empty SOURCE_SHA to be lowercase 40-hex and ordinal-equal to live HEAD, permits a local checkout with SOURCE_SHA empty or unset to differ from the historical baseline, and keeps discovery sourceSha bound to live HEAD. Discovery remains exactly 8 probes with seven mutations; all existing inventory, gap, source, binding, fixture, and root thresholds remain unchanged."
$expectedManifestThresholds = [ordered]@{
    minimumDiscovery = 8
    maximumUnexpectedSkips = 0
    requiredMutationControls = 7
    requiredBoundaries = 18
    requiredRequirementIds = 34
    requiredCurrentDispositionRecords = 114
    requiredQualificationLanes = 14
    requiredFixtures = 4
    requiredDataRecords = 17
    requiredPersistedDataTargets = 16
    requiredApplicationOwnedTargets = 12
    requiredExternalReadOnlyTargets = 4
    requiredCurrentWritableTargets = 10
    requiredLatentWritableTargets = 2
    requiredOracleRecords = 28
    requiredProtocolContracts = 15
    requiredResources = 11
    requiredWindowsJourneys = 5
    requiredKnownGaps = 35
    requiredSupportedEnvironments = 5
    requiredProductionRoots = 2
    requiredProductionFiles = 140
    requiredReviewerSources = 21
    requiredCleanReviewBindings = 15
    artifactRetentionDays = 90
}
$expectedFutureApprovalContracts = [ordered]@{
    "CURRENT:AC-FUT-001" = [PSCustomObject]@{
        ApprovalId = "APP-007"
        BaselineTreatment = "future-red-only"
        TestIds = @("P0A.1-V-STATIC-STATIC-CONTRACT")
    }
    "CURRENT:FR-FUT-001" = [PSCustomObject]@{
        ApprovalId = "APP-007"
        BaselineTreatment = "future-red-only"
        TestIds = @("P0A.1-V-STATIC-STATIC-CONTRACT")
    }
    "CURRENT:AC-FUT-002" = [PSCustomObject]@{
        ApprovalId = "APP-008"
        BaselineTreatment = "baseline-plus-future-red"
        TestIds = @("P0A.1-V-STATIC-STATIC-CONTRACT", "P0A.9-V-LEGACY-LEGACY-REGRESSION")
    }
    "CURRENT:FR-FUT-002" = [PSCustomObject]@{
        ApprovalId = "APP-008"
        BaselineTreatment = "baseline-plus-future-red"
        TestIds = @("P0A.1-V-STATIC-STATIC-CONTRACT", "P0A.9-V-LEGACY-LEGACY-REGRESSION")
    }
    "CURRENT:AC-FUT-003" = [PSCustomObject]@{
        ApprovalId = "APP-009"
        BaselineTreatment = "future-red-only"
        TestIds = @("P0A.1-V-STATIC-STATIC-CONTRACT")
    }
    "CURRENT:FR-FUT-003" = [PSCustomObject]@{
        ApprovalId = "APP-009"
        BaselineTreatment = "future-red-only"
        TestIds = @("P0A.1-V-STATIC-STATIC-CONTRACT")
    }
}
$expectedTraceEntryOwnerTestIds = [ordered]@{
    "PRD:AC-FR-017-01" = @(
        "P0B.3e-V-ACCESS-ACCESSIBILITY-JOURNEY",
        "P4.5e-V-ACCESS-ACCESSIBILITY-JOURNEY"
    )
    "CURRENT:FR-PET-008" = @(
        "P0A.4d-V-UNIT-UNIT-SPEC",
        "P0A.6-V-WPF-WPF-STATE",
        "P0A.9-V-LEGACY-LEGACY-REGRESSION",
        "P4.5c-V-WPF-WPF-STATE"
    )
    "CURRENT:FR-AI-006" = @(
        "P0A.5e-V-CONTRACT-CONTRACT-COMPATIBILITY",
        "P0A.9-V-LEGACY-LEGACY-REGRESSION",
        "P9.2-V-COMPONENT-COMPONENT-FLOW"
    )
    "CURRENT:FR-AI-007" = @(
        "P0A.5e-V-CONTRACT-CONTRACT-COMPATIBILITY",
        "P0A.9-V-LEGACY-LEGACY-REGRESSION",
        "P9.2-V-FIXTURE-E2E-FIXTURE-JOURNEY"
    )
    "CURRENT:AR-004" = @(
        "P0A.5a-V-COMPONENT-COMPONENT-FLOW",
        "P0A.9-V-LEGACY-LEGACY-REGRESSION",
        "P2.3-V-CONTRACT-CONTRACT-COMPATIBILITY"
    )
    "PRD:AC-FR-014-02" = @(
        "P3.3-V-CONTRACT-CONTRACT-COMPATIBILITY",
        "P3.3-V-SECURITY-SECURITY-CONTROLS"
    )
}
$expectedReviewerSources = @(
    "REQUIREMENTS.md",
    "docs/prd/jarvis_assistant_prd.md",
    "docs/design/jarvis_assistant_design.md",
    "docs/ui-spec/jarvis_assistant_ui_spec.md",
    "docs/plans/20260722-jarvis-assistant-tdd-checklist.md",
    "docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md",
    "docs/verification/traceability-v2.yml",
    "docs/verification/manifests/P0A.1-v9.yml",
    "src/AemeathDesktopPet",
    "python-backend/aemeath_agent",
    "tests/fixtures/preservation/v1/data-v5.json",
    "tests/fixtures/preservation/v1/oracles-v1.json",
    "tests/fixtures/preservation/v1/protocol-v3.json",
    "tests/fixtures/preservation/v1/resources-v1.json",
    "docs/verification/preservation-spec-v5.yml",
    "python-backend/pyproject.toml",
    ".github/workflows/release.yml",
    "tools/verification/Test-PreservationSpecification.ps1",
    "tools/ci/CiDeliveryContract.psm1",
    "docs/verification/manifests/D0.4-v3.yml",
    "docs/verification/environments/D0.4-readiness-v1.json"
)
$expectedTopLevelProperties = @(
    "schemaVersion",
    "documentType",
    "specId",
    "revision",
    "status",
    "previousSpecification",
    "governingManifest",
    "baseline",
    "sourceIdentityPolicy",
    "sourceHashMethod",
    "sources",
    "traceability",
    "claimVerificationPolicy",
    "inventories",
    "boundaries",
    "qualificationLanes",
    "artifacts",
    "supportedEnvironments",
    "environmentReadinessInterpretation",
    "knownGaps",
    "provenance"
)
$probeCount = 0

function Add-Failure {
    param(
        [Collections.Generic.List[string]]$Failures,
        [string]$Code
    )

    if (-not $Failures.Contains($Code)) {
        [void]$Failures.Add($Code)
    }
}

function Get-PropertyValue {
    param(
        [object]$InputObject,
        [string]$Name
    )

    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-PropertyNames {
    param([object]$InputObject)

    if ($null -eq $InputObject) { return @() }
    return @($InputObject.PSObject.Properties.Name)
}

function Test-HasProperties {
    param(
        [object]$InputObject,
        [string[]]$Names
    )

    if ($null -eq $InputObject) { return $false }
    foreach ($name in $Names) {
        if ($null -eq $InputObject.PSObject.Properties[$name]) { return $false }
    }
    return $true
}

function Get-ArrayProperty {
    param(
        [object]$InputObject,
        [string]$Name
    )

    $value = Get-PropertyValue $InputObject $Name
    if ($null -eq $value) { return @() }
    return @($value)
}

function Get-ObjectIds {
    param([object[]]$Records)

    return @($Records | ForEach-Object { [string](Get-PropertyValue $_ "id") })
}

function Test-ExactOrdinalSet {
    param(
        [string[]]$Actual,
        [string[]]$Expected
    )

    if (@($Actual).Count -ne @($Expected).Count) { return $false }
    $actualSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($item in @($Actual)) {
        if ([string]::IsNullOrWhiteSpace($item) -or -not $actualSet.Add($item)) { return $false }
    }
    foreach ($item in @($Expected)) {
        if (-not $actualSet.Contains($item)) { return $false }
    }
    return $true
}

function Test-IsSubset {
    param(
        [string[]]$Actual,
        [string[]]$Allowed
    )

    $allowedSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($item in @($Allowed)) { [void]$allowedSet.Add($item) }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($item in @($Actual)) {
        if ([string]::IsNullOrWhiteSpace($item) -or
            -not $allowedSet.Contains($item) -or
            -not $seen.Add($item)) {
            return $false
        }
    }
    return $true
}

function Get-UniqueOrdinalValues {
    param([object[]]$Values)

    $set = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in @($Values)) {
        $text = [string]$value
        if (-not [string]::IsNullOrWhiteSpace($text)) { [void]$set.Add($text) }
    }
    return @($set)
}

function Test-ExactScalarValue {
    param(
        [object]$Actual,
        [object]$Expected
    )

    if ($null -eq $Actual -or $null -eq $Expected) {
        return $null -eq $Actual -and $null -eq $Expected
    }
    return [string]$Actual -ceq [string]$Expected
}

function Test-ExactPathSemantics {
    param(
        [object]$Actual,
        [object]$Expected
    )

    $propertyNames = @("authority", "default", "fallback", "configuredBy", "relativeTo")
    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $Actual) $propertyNames) -or
        -not (Test-ExactOrdinalSet @(Get-PropertyNames $Expected) $propertyNames)) {
        return $false
    }
    foreach ($propertyName in $propertyNames) {
        if (-not (Test-ExactScalarValue `
                    (Get-PropertyValue $Actual $propertyName) `
                    (Get-PropertyValue $Expected $propertyName))) {
            return $false
        }
    }
    return $true
}

function Get-DataTargetContracts {
    param([object]$DataFixture)

    $contracts = [ordered]@{}
    $records = @(Get-ArrayProperty $DataFixture "records")
    foreach ($targetId in $expectedPersistedDataTargetIds) {
        $targetRecords = @($records | Where-Object {
                [string](Get-PropertyValue $_ "targetId") -ceq $targetId
            })
        if ($targetRecords.Count -eq 0) { continue }

        $ownership = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                    Get-PropertyValue $_ "ownership"
                }))
        $access = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                    Get-PropertyValue $_ "access"
                }))
        $lifecycle = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                    Get-PropertyValue $_ "lifecycle"
                }))
        $paths = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                    Get-PropertyValue $_ "path"
                }))
        $pathSemantics = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                    (Get-PropertyValue $_ "pathSemantics") | ConvertTo-Json -Depth 10 -Compress
                }))
        $contracts[$targetId] = [PSCustomObject]@{
            Valid = $ownership.Count -eq 1 -and $access.Count -eq 1 -and
                $lifecycle.Count -eq 1 -and $paths.Count -eq 1 -and $pathSemantics.Count -eq 1
            Ownership = if ($ownership.Count -eq 1) { $ownership[0] } else { $null }
            Access = if ($access.Count -eq 1) { $access[0] } else { $null }
            Lifecycle = if ($lifecycle.Count -eq 1) { $lifecycle[0] } else { $null }
            Path = if ($paths.Count -eq 1) { $paths[0] } else { $null }
            PathSemantics = Get-PropertyValue $targetRecords[0] "pathSemantics"
            SourceLocators = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                        Get-ArrayProperty $_ "sourceLocators"
                    }))
            BoundaryIds = @(Get-UniqueOrdinalValues @($targetRecords | ForEach-Object {
                        Get-ArrayProperty $_ "boundaryIds"
                    }))
            RecordIds = @($targetRecords | ForEach-Object { [string](Get-PropertyValue $_ "id") })
        }
    }
    return $contracts
}

function Get-ExpectedLaneBehaviors {
    param([string]$LaneId)

    if ($expectedSpecialLaneBehaviors.Contains($LaneId)) {
        return @($expectedSpecialLaneBehaviors[$LaneId])
    }
    $catalogRows = @($script:liveContext.Traceability.testCatalog | Where-Object {
        [string]$_.lane -ceq $LaneId -and [string]$_.ownerStep -clike "P0A.*"
    })
    return @(Get-UniqueOrdinalValues @($catalogRows | ForEach-Object { $_.behaviorIds }))
}

function Get-BytesSha256 {
    param([byte[]]$Bytes)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
}

function Get-RawFileSha256 {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-StrictUtf8Text {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return $null
    }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    try {
        return $utf8.GetString($bytes)
    } catch {
        return $null
    }
}

function Get-NormalizedTextSha256 {
    param(
        [string]$Path,
        [string]$Mode
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $content = Get-StrictUtf8Text $Path
    if ($null -eq $content) { return $null }
    $content = $content.Replace("`r`n", "`n").Replace("`r", "`n")
    if ($Mode -ceq "normalized-checkbox-text") {
        $content = [regex]::Replace($content, '(?m)^(-\s+\[)[xX](\])', '$1 $2')
    } elseif ($Mode -cne "normalized-text") {
        return $null
    }
    return Get-BytesSha256 ([Text.Encoding]::UTF8.GetBytes($content))
}

function Get-StrictJsonValue {
    param(
        [string]$Path,
        [string]$Diagnostic
    )

    $content = Get-StrictUtf8Text $Path
    if ($null -eq $content) {
        throw "[$Diagnostic] Input must be strict UTF-8 without BOM: $Path"
    }
    try {
        return $content | ConvertFrom-Json
    } catch {
        throw "[$Diagnostic] Input is not valid JSON: $Path"
    }
}

function Resolve-RepositoryPath {
    param([string]$RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath)) {
        return $null
    }
    try {
        $fullPath = [IO.Path]::GetFullPath((Join-Path $repositoryRoot $RelativePath))
    } catch {
        return $null
    }
    $rootPrefix = $repositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $pathComparison = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        [StringComparison]::OrdinalIgnoreCase
    } else {
        [StringComparison]::Ordinal
    }
    if (-not $fullPath.StartsWith($rootPrefix, $pathComparison)) { return $null }
    return $fullPath
}

function Get-FixedInputAuthorityObservation {
    param(
        [string]$RelativePath,
        [object]$Definition
    )

    $observation = [PSCustomObject]@{
        Path = $RelativePath
        Sha256 = $null
        StrictUtf8 = $false
        KindValid = $false
        NormalizedTextSha256 = $null
    }
    try {
        $fullPath = Resolve-RepositoryPath $RelativePath
        if ($null -eq $fullPath) { return $observation }
        $strictText = Get-StrictUtf8Text $fullPath
        $observation.Sha256 = Get-RawFileSha256 $fullPath
        $observation.StrictUtf8 = $null -ne $strictText
        $kind = [string](Get-PropertyValue $Definition "Kind")
        if ($null -ne $strictText -and -not [string]::IsNullOrWhiteSpace($strictText) -and
            $kind -ceq "strict-json") {
            [void]($strictText | ConvertFrom-Json)
            $observation.KindValid = $true
        } elseif ($null -ne $strictText -and -not [string]::IsNullOrWhiteSpace($strictText) -and
            $kind -ceq "strict-text") {
            $observation.KindValid = $true
        }
        if ($null -ne (Get-PropertyValue $Definition "NormalizedTextSha256")) {
            $observation.NormalizedTextSha256 =
                Get-NormalizedTextSha256 $fullPath "normalized-text"
        }
    } catch {
        $observation.StrictUtf8 = $false
        $observation.KindValid = $false
        $observation.NormalizedTextSha256 = $null
    }
    return $observation
}

function Get-GitHeadSha {
    $output = @(& git -C $repositoryRoot rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or $output.Count -ne 1 -or
        [string]$output[0] -cnotmatch '^[0-9a-f]{40}$') {
        return $null
    }
    return [string]$output[0]
}

function Get-SourceIdentityFailures {
    param(
        [AllowNull()][string]$LiveHeadSha,
        [AllowNull()][string]$CiSourceSha
    )

    $failures = [Collections.Generic.List[string]]::new()
    $liveHeadValid = $null -ne $LiveHeadSha -and
        $LiveHeadSha -cmatch '^[0-9a-f]{40}$'
    if (-not $liveHeadValid) {
        $failures.Add("source-identity:live-head-format")
    }

    $ciSourceActive = $null -ne $CiSourceSha -and $CiSourceSha.Length -gt 0
    if ($ciSourceActive) {
        $ciSourceValid = $CiSourceSha -cmatch '^[0-9a-f]{40}$'
        if (-not $ciSourceValid) {
            $failures.Add("source-identity:source-sha-format")
        } elseif ($liveHeadValid -and
            -not [StringComparer]::Ordinal.Equals($CiSourceSha, $LiveHeadSha)) {
            $failures.Add("source-identity:source-sha-mismatch")
        }
    }
    return $failures.ToArray()
}

function Get-FixedInputAuthorityFailures {
    param([object]$Context)

    $failures = [Collections.Generic.List[string]]::new()
    $authorityFiles = Get-PropertyValue $Context "FixedInputAuthorities"
    $authorityMapValid = $authorityFiles -is [Collections.IDictionary]
    $authorityKeys = if ($authorityMapValid) { @($authorityFiles.Keys) } else { @() }
    if (-not (Test-ExactOrdinalSet $authorityKeys @($expectedFixedInputAuthorities.Keys))) {
        Add-Failure $failures "authority-file-set"
    }
    foreach ($relativePath in $expectedFixedInputAuthorities.Keys) {
        $observation = if ($authorityMapValid -and $authorityFiles.Contains($relativePath)) {
            $authorityFiles[$relativePath]
        } else {
            $null
        }
        $strictUtf8 = Get-PropertyValue $observation "StrictUtf8"
        $kindValid = Get-PropertyValue $observation "KindValid"
        $definition = $expectedFixedInputAuthorities[$relativePath]
        if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $observation) @(
                    "Path", "Sha256", "StrictUtf8", "KindValid", "NormalizedTextSha256"
                )) -or
            [string](Get-PropertyValue $observation "Path") -cne $relativePath -or
            [string](Get-PropertyValue $observation "Sha256") -cne
                [string](Get-PropertyValue $definition "Sha256") -or
            $strictUtf8 -isnot [bool] -or $strictUtf8 -ne $true -or
            $kindValid -isnot [bool] -or $kindValid -ne $true -or
            -not (Test-ExactScalarValue `
                (Get-PropertyValue $observation "NormalizedTextSha256") `
                (Get-PropertyValue $definition "NormalizedTextSha256"))) {
            Add-Failure $failures "authority-file:$relativePath"
        }
    }

    foreach ($identityFailure in @(Get-SourceIdentityFailures `
            (Get-PropertyValue $Context "GitHeadSha") `
            (Get-PropertyValue $Context "CiSourceSha"))) {
        Add-Failure $failures $identityFailure
    }

    $sourceHashes = Get-PropertyValue $Context "SourceHashes"
    $sourceHashMapValid = $sourceHashes -is [Collections.IDictionary]
    $sourceHashKeys = if ($sourceHashMapValid) { @($sourceHashes.Keys) } else { @() }
    if (-not (Test-ExactOrdinalSet $sourceHashKeys @($expectedSources.Keys))) {
        Add-Failure $failures "source-hash-set"
    }
    foreach ($sourceId in $expectedSources.Keys) {
        $actualHash = if ($sourceHashMapValid -and $sourceHashes.Contains($sourceId)) {
            $sourceHashes[$sourceId]
        } else {
            $null
        }
        if ([string]$actualHash -cne [string]$expectedSources[$sourceId].Sha256) {
            Add-Failure $failures "source-hash:$sourceId"
        }
    }

    $rootIdentities = Get-PropertyValue $Context "ProductionRoots"
    $rootMapValid = $rootIdentities -is [Collections.IDictionary]
    $rootKeys = if ($rootMapValid) { @($rootIdentities.Keys) } else { @() }
    if (-not (Test-ExactOrdinalSet $rootKeys @($expectedProductionRoots.Keys))) {
        Add-Failure $failures "production-root-set"
    }
    foreach ($rootPath in $expectedProductionRoots.Keys) {
        $identity = if ($rootMapValid -and $rootIdentities.Contains($rootPath)) {
            $rootIdentities[$rootPath]
        } else {
            $null
        }
        if ([string](Get-PropertyValue $identity "Path") -cne $rootPath -or
            [long](Get-PropertyValue $identity "FileCount") -ne
                [long]$expectedProductionRoots[$rootPath].FileCount -or
            [string](Get-PropertyValue $identity "Sha256") -cne
                [string]$expectedProductionRoots[$rootPath].Sha256) {
            Add-Failure $failures "production-root:$rootPath"
        }
    }
    return $failures.ToArray()
}

function Assert-FixedInputAuthority {
    param([object]$Context)

    $authorityFailures = @(Get-FixedInputAuthorityFailures $Context)
    if ($authorityFailures.Count -ne 0) {
        throw "[P0A1-FIXED-INPUT-AUTHORITY] Fixed authority drift: $($authorityFailures -join ', ')."
    }
}

function Assert-FixedInputAuthorityMutationGuards {
    param([object]$Context)

    $authorityFiles = Get-PropertyValue $Context "FixedInputAuthorities"
    $sourceHashes = Get-PropertyValue $Context "SourceHashes"
    $rootIdentities = Get-PropertyValue $Context "ProductionRoots"
    $gitHeadSha = Get-PropertyValue $Context "GitHeadSha"

    $specificationObservation = $authorityFiles[$specificationRelativePath]
    $originalSpecificationHash = $specificationObservation.Sha256
    try {
        $specificationObservation.Sha256 = "0000000000000000000000000000000000000000000000000000000000000000"
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "authority-file:$specificationRelativePath") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] Raw-hash mutation was not rejected."
        }
    } finally {
        $specificationObservation.Sha256 = $originalSpecificationHash
    }

    $capabilityObservation = $authorityFiles["docs/verification/manifests/D0.4-v3.yml"]
    $originalNormalizedHash = $capabilityObservation.NormalizedTextSha256
    try {
        $capabilityObservation.NormalizedTextSha256 =
            "0000000000000000000000000000000000000000000000000000000000000000"
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "authority-file:docs/verification/manifests/D0.4-v3.yml") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] Normalized-text mutation was not rejected."
        }
    } finally {
        $capabilityObservation.NormalizedTextSha256 = $originalNormalizedHash
    }

    try {
        $Context.GitHeadSha = "ABC"
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "source-identity:live-head-format") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] Git-HEAD mutation was not rejected."
        }
    } finally {
        $Context.GitHeadSha = $gitHeadSha
    }

    $traceObservation = $authorityFiles["docs/verification/traceability-v2.yml"]
    $originalTraceUtf8 = $traceObservation.StrictUtf8
    try {
        $traceObservation.StrictUtf8 = $false
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "authority-file:docs/verification/traceability-v2.yml") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] UTF-8 mutation was not rejected."
        }
    } finally {
        $traceObservation.StrictUtf8 = $originalTraceUtf8
    }

    $dataObservation = $authorityFiles["tests/fixtures/preservation/v1/data-v5.json"]
    $originalDataPath = $dataObservation.Path
    try {
        $dataObservation.Path = "tests/fixtures/preservation/v1/data-v4.json"
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "authority-file:tests/fixtures/preservation/v1/data-v5.json") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] Path mutation was not rejected."
        }
    } finally {
        $dataObservation.Path = $originalDataPath
    }

    $originalSourceHash = $sourceHashes["CURRENT:REQUIREMENTS"]
    try {
        $sourceHashes["CURRENT:REQUIREMENTS"] =
            "0000000000000000000000000000000000000000000000000000000000000000"
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "source-hash:CURRENT:REQUIREMENTS") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] Source-hash mutation was not rejected."
        }
    } finally {
        $sourceHashes["CURRENT:REQUIREMENTS"] = $originalSourceHash
    }

    $desktopRoot = $rootIdentities["src/AemeathDesktopPet"]
    $originalFileCount = $desktopRoot.FileCount
    try {
        $desktopRoot.FileCount = [long]$originalFileCount - 1
        if (@(Get-FixedInputAuthorityFailures $Context) -cnotcontains
            "production-root:src/AemeathDesktopPet") {
            throw "[P0A1-FIXED-INPUT-AUTHORITY] Production-root mutation was not rejected."
        }
    } finally {
        $desktopRoot.FileCount = $originalFileCount
    }
}

function Assert-SourceIdentityMutationGuards {
    $validDifferentHead = "1111111111111111111111111111111111111111"
    $validOtherHead = "2222222222222222222222222222222222222222"
    if ([StringComparer]::Ordinal.Equals($validDifferentHead, $frozenBaselineSha)) {
        throw "[P0A1-SOURCE-IDENTITY-GUARD] Synthetic live HEAD equals historical baseline."
    }
    if (@(Get-SourceIdentityFailures $validDifferentHead $null).Count -ne 0 -or
        @(Get-SourceIdentityFailures $validDifferentHead "").Count -ne 0 -or
        @(Get-SourceIdentityFailures $validDifferentHead $validDifferentHead).Count -ne 0 -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures $validDifferentHead $validOtherHead) `
            @("source-identity:source-sha-mismatch")) -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures $validDifferentHead "ABC") `
            @("source-identity:source-sha-format")) -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures "ABC" $null) `
            @("source-identity:live-head-format")) -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures `
                $validDifferentHead `
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA") `
            @("source-identity:source-sha-format")) -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures `
                $validDifferentHead `
                " 1111111111111111111111111111111111111111") `
            @("source-identity:source-sha-format")) -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures `
                $validDifferentHead `
                "1111111111111111111111111111111111111111 ") `
            @("source-identity:source-sha-format")) -or
        -not (Test-ExactOrdinalSet `
            @(Get-SourceIdentityFailures `
                "ABC" `
                "2222222222222222222222222222222222222222") `
            @("source-identity:live-head-format"))) {
        throw "[P0A1-SOURCE-IDENTITY-GUARD] Source identity truth-table guard failed."
    }
}

function Get-ProductionRootIdentity {
    param([string]$RelativeRoot)

    $fullRoot = Resolve-RepositoryPath $RelativeRoot
    if ($null -eq $fullRoot -or -not (Test-Path -LiteralPath $fullRoot -PathType Container)) {
        return $null
    }

    $rootItem = Get-Item -Force -LiteralPath $fullRoot
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return $null }
    $pathComparison = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        [StringComparison]::OrdinalIgnoreCase
    } else {
        [StringComparison]::Ordinal
    }
    $rootPrefix = $fullRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $records = [Collections.Generic.List[string]]::new()
    [long]$byteCount = 0
    foreach ($file in @(Get-ChildItem -Force -LiteralPath $fullRoot -Recurse -File)) {
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        $directory = $file.Directory
        $reachedRoot = $false
        $hasReparsePoint = $false
        while ($null -ne $directory) {
            if (($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                $hasReparsePoint = $true
                break
            }
            if ($directory.FullName.Equals($fullRoot, $pathComparison)) {
                $reachedRoot = $true
                break
            }
            $directory = $directory.Parent
        }
        if ($hasReparsePoint -or -not $reachedRoot) { continue }
        $relativePath = $file.FullName.Substring($rootPrefix.Length).Replace('\', '/')
        if ($relativePath -match '(^|/)(bin|obj|__pycache__|\.pytest_cache)(/|$)' -or
            $relativePath.EndsWith(".pyc", [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $byteCount += [long]$file.Length
        $records.Add("$relativePath|$($file.Length)|$(Get-RawFileSha256 $file.FullName)")
    }
    $recordArray = $records.ToArray()
    [Array]::Sort($recordArray, [StringComparer]::Ordinal)
    $digestInput = [string]::Join("`n", $recordArray)
    return [PSCustomObject]@{
        Path = $RelativeRoot
        FileCount = $recordArray.Count
        ByteCount = $byteCount
        Sha256 = Get-BytesSha256 ([Text.Encoding]::UTF8.GetBytes($digestInput))
    }
}

function Copy-JsonValue {
    param([object]$Value)

    return ($Value | ConvertTo-Json -Depth 100 -Compress) | ConvertFrom-Json
}

function Get-AuthorityObservationContext {
    $fixedInputAuthorities = [ordered]@{}
    foreach ($relativePath in $expectedFixedInputAuthorities.Keys) {
        $fixedInputAuthorities[$relativePath] = Get-FixedInputAuthorityObservation `
            $relativePath `
            $expectedFixedInputAuthorities[$relativePath]
    }
    $rootIdentities = [ordered]@{}
    foreach ($rootPath in $expectedProductionRoots.Keys) {
        try {
            $rootIdentities[$rootPath] = Get-ProductionRootIdentity $rootPath
        } catch {
            $rootIdentities[$rootPath] = $null
        }
    }
    $sourceHashes = [ordered]@{}
    foreach ($sourceId in $expectedSources.Keys) {
        $source = $expectedSources[$sourceId]
        try {
            $sourcePath = Resolve-RepositoryPath $source.Path
            $sourceHashes[$sourceId] = if ($null -eq $sourcePath) {
                $null
            } else {
                Get-NormalizedTextSha256 $sourcePath $source.HashMode
            }
        } catch {
            $sourceHashes[$sourceId] = $null
        }
    }
    return [PSCustomObject]@{
        FixedInputAuthorities = $fixedInputAuthorities
        ProductionRoots = $rootIdentities
        SourceHashes = $sourceHashes
        CiSourceSha = [Environment]::GetEnvironmentVariable("SOURCE_SHA")
        GitHeadSha = try { Get-GitHeadSha } catch { $null }
    }
}

function Get-LiveContext {
    param([object]$AuthorityContext)

    $manifest = Get-StrictJsonValue $manifestPath "P0A1-MANIFEST-INPUT"
    $predecessorSpecification = Get-StrictJsonValue `
        $predecessorSpecificationPath `
        "P0A1-SPEC-PREDECESSOR"
    $v1Invalidation = Get-StrictJsonValue $v1InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $v2Invalidation = Get-StrictJsonValue $v2InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $v3Invalidation = Get-StrictJsonValue $v3InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $v4Invalidation = Get-StrictJsonValue $v4InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $v5ReplacementInvalidation = Get-StrictJsonValue `
        $v5ReplacementInvalidationPath `
        "P0A1-MANIFEST-CONTRACT"
    $v6Invalidation = Get-StrictJsonValue $v6InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $v7Invalidation = Get-StrictJsonValue $v7InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $v8Invalidation = Get-StrictJsonValue $v8InvalidationPath "P0A1-MANIFEST-CONTRACT"
    $traceability = Get-StrictJsonValue $traceabilityPath "P0A1-TRACEABILITY-INPUT"
    $fixtures = [ordered]@{}
    foreach ($fixtureId in $expectedFixtureArtifacts.Keys) {
        $definition = $expectedFixtureArtifacts[$fixtureId]
        $fullPath = Resolve-RepositoryPath $definition.Path
        $fixtures[$fixtureId] = Get-StrictJsonValue $fullPath "P0A1-FIXTURE-INPUT"
    }
    return [PSCustomObject]@{
        FixedInputAuthorities = Get-PropertyValue $AuthorityContext "FixedInputAuthorities"
        Manifest = $manifest
        ManifestSha256 = Get-RawFileSha256 $manifestPath
        PredecessorSpecification = $predecessorSpecification
        V1Invalidation = $v1Invalidation
        V1InvalidationSha256 = Get-RawFileSha256 $v1InvalidationPath
        V2Invalidation = $v2Invalidation
        V2InvalidationSha256 = Get-RawFileSha256 $v2InvalidationPath
        V3Invalidation = $v3Invalidation
        V3InvalidationSha256 = Get-RawFileSha256 $v3InvalidationPath
        V4Invalidation = $v4Invalidation
        V4InvalidationSha256 = Get-RawFileSha256 $v4InvalidationPath
        V5ReplacementInvalidation = $v5ReplacementInvalidation
        V5ReplacementInvalidationSha256 = Get-RawFileSha256 $v5ReplacementInvalidationPath
        V6Invalidation = $v6Invalidation
        V6InvalidationSha256 = Get-RawFileSha256 $v6InvalidationPath
        V7Invalidation = $v7Invalidation
        V7InvalidationSha256 = Get-RawFileSha256 $v7InvalidationPath
        V8Invalidation = $v8Invalidation
        V8InvalidationSha256 = Get-RawFileSha256 $v8InvalidationPath
        Traceability = $traceability
        TraceabilitySha256 = Get-RawFileSha256 $traceabilityPath
        PredecessorTraceabilitySha256 = Get-RawFileSha256 $predecessorTraceabilityPath
        Fixtures = $fixtures
        ProductionRoots = Get-PropertyValue $AuthorityContext "ProductionRoots"
        SourceHashes = Get-PropertyValue $AuthorityContext "SourceHashes"
        GitHeadSha = Get-PropertyValue $AuthorityContext "GitHeadSha"
        CiSourceSha = Get-PropertyValue $AuthorityContext "CiSourceSha"
    }
}

function Test-Inventory {
    param(
        [object]$Inventories,
        [Collections.Generic.List[string]]$Failures
    )

    $inventoryNames = @("components", "publicBehaviors", "persistedData", "integrationBoundaries", "windowsJourneys")
    if (-not (Test-HasProperties $Inventories $inventoryNames)) {
        Add-Failure $Failures "P0A1-INVENTORY-SHAPE"
        return
    }
    foreach ($name in $inventoryNames) {
        $records = @(Get-ArrayProperty $Inventories $name)
        $ids = @(Get-ObjectIds $records)
        $uniqueIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($record in $records) {
            $id = [string](Get-PropertyValue $record "id")
            if ([string]::IsNullOrWhiteSpace($id) -or -not $uniqueIds.Add($id)) {
                Add-Failure $Failures "P0A1-INVENTORY-IDENTITY"
            }
        }
        if ($records.Count -eq 0) { Add-Failure $Failures "P0A1-INVENTORY-COVERAGE" }
    }

    $publicBehaviorIds = @(Get-ObjectIds @(Get-ArrayProperty $Inventories "publicBehaviors"))
    if (-not (Test-ExactOrdinalSet $publicBehaviorIds $expectedBoundaryIds)) {
        Add-Failure $Failures "P0A1-PB-COVERAGE"
    }
    $journeys = @(Get-ArrayProperty $Inventories "windowsJourneys")
    if ($journeys.Count -ne 5) { Add-Failure $Failures "P0A1-JOURNEY-COVERAGE" }
}

function Test-DataFixtureContract {
    param([Collections.Generic.List[string]]$Failures)

    $fixture = $script:liveContext.Fixtures["P0A1-DATA-V5"]
    $records = @(Get-ArrayProperty $fixture "records")
    $targetIds = @($records | ForEach-Object { [string](Get-PropertyValue $_ "targetId") })
    $census = Get-PropertyValue $fixture "targetCensus"
    $predecessor = Get-PropertyValue $fixture "predecessor"
    $lineage = @(Get-ArrayProperty $fixture "lineage")
    $privacy = Get-PropertyValue $fixture "privacy"
    $containsSecrets = Get-PropertyValue $privacy "containsSecrets"
    $containsPersonalData = Get-PropertyValue $privacy "containsPersonalData"

    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $fixture) @(
                "schemaVersion", "fixtureId", "predecessor", "lineage", "privacy",
                "coveragePolicy", "targetCensus", "records"
            )) -or
        [long](Get-PropertyValue $fixture "schemaVersion") -ne 5 -or
        [string](Get-PropertyValue $fixture "fixtureId") -cne "P0A1-DATA-V5" -or
        $records.Count -ne 17 -or
        -not (Test-ExactOrdinalSet @(Get-ObjectIds $records) $expectedDataRecordIds) -or
        -not (Test-ExactOrdinalSet @(Get-UniqueOrdinalValues $targetIds) $expectedPersistedDataTargetIds)) {
        Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
    }
    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $privacy) @(
                "containsSecrets", "containsPersonalData", "canary"
            )) -or
        $containsSecrets -isnot [bool] -or $containsSecrets -ne $false -or
        $containsPersonalData -isnot [bool] -or $containsPersonalData -ne $false -or
        [string](Get-PropertyValue $privacy "canary") -cne "AEMEATH_FIXTURE_USER" -or
        [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $fixture "coveragePolicy"))) {
        Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
    }

    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $predecessor) @(
                "fixtureId", "path", "sha256", "recordCount", "atomicTargetCount"
            )) -or
        [string](Get-PropertyValue $predecessor "fixtureId") -cne $expectedDataFixturePredecessor.fixtureId -or
        [string](Get-PropertyValue $predecessor "path") -cne $expectedDataFixturePredecessor.path -or
        [string](Get-PropertyValue $predecessor "sha256") -cne $expectedDataFixturePredecessor.sha256 -or
        [long](Get-PropertyValue $predecessor "recordCount") -ne $expectedDataFixturePredecessor.recordCount -or
        [long](Get-PropertyValue $predecessor "atomicTargetCount") -ne
            $expectedDataFixturePredecessor.atomicTargetCount -or
        -not (Test-ExactOrdinalSet @($lineage | ForEach-Object {
                    [string](Get-PropertyValue $_ "fixtureId")
                }) @($expectedDataFixtureLineage.Keys))) {
        Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
    }
    foreach ($fixtureId in $expectedDataFixtureLineage.Keys) {
        $matches = @($lineage | Where-Object { [string](Get-PropertyValue $_ "fixtureId") -ceq $fixtureId })
        $expected = $expectedDataFixtureLineage[$fixtureId]
        if ($matches.Count -ne 1 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $matches[0]) @(
                    "fixtureId", "path", "sha256", "recordCount"
                )) -or
            [string](Get-PropertyValue $matches[0] "path") -cne $expected.Path -or
            [string](Get-PropertyValue $matches[0] "sha256") -cne $expected.Sha256 -or
            [long](Get-PropertyValue $matches[0] "recordCount") -ne $expected.RecordCount) {
            Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
        }
    }

    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $census) @($expectedPersistedDataCensus.Keys))) {
        Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
    } else {
        foreach ($name in $expectedPersistedDataCensus.Keys) {
            if ([long](Get-PropertyValue $census $name) -ne [long]$expectedPersistedDataCensus[$name]) {
                Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
            }
        }
    }

    $allowedOwnership = @("application", "external-user", "external-operator")
    $allowedAccess = @("read-write", "read-write-api", "read-only")
    $allowedLifecycle = @(
        "current-production-writable",
        "current-production-conditionally-writable",
        "current-production-writable-on-first-access",
        "latent-writable-currently-read-only",
        "external-user-managed",
        "external-operator-managed"
    )
    $allowedReachability = @("current", "conditional", "latent", "forbidden")
    foreach ($record in $records) {
        if (-not (Test-HasProperties $record @(
                    "id", "targetId", "boundaryIds", "ownership", "access", "lifecycle", "path",
                    "pathSemantics", "sourceLocators", "mutationContract", "reachability",
                    "fixtureRole", "contractRole", "completeness"
                )) -or
            $allowedOwnership -cnotcontains [string](Get-PropertyValue $record "ownership") -or
            $allowedAccess -cnotcontains [string](Get-PropertyValue $record "access") -or
            $allowedLifecycle -cnotcontains [string](Get-PropertyValue $record "lifecycle") -or
            [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $record "path")) -or
            @(Get-ArrayProperty $record "sourceLocators").Count -eq 0 -or
            -not (Test-IsSubset @(Get-ArrayProperty $record "boundaryIds") $expectedBoundaryIds) -or
            @(Get-ArrayProperty $record "boundaryIds").Count -eq 0) {
            Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
        }

        $pathSemantics = Get-PropertyValue $record "pathSemantics"
        if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $pathSemantics) @(
                    "authority", "default", "fallback", "configuredBy", "relativeTo"
                )) -or
            [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $pathSemantics "authority"))) {
            Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
        }
        foreach ($name in @("default", "fallback", "configuredBy", "relativeTo")) {
            $value = Get-PropertyValue $pathSemantics $name
            if ($null -ne $value -and $value -isnot [string]) {
                Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
            }
        }

        $mutationContract = Get-PropertyValue $record "mutationContract"
        $reachability = Get-PropertyValue $record "reachability"
        if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $mutationContract) @("read", "write", "delete")) -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $reachability) @("read", "write", "delete"))) {
            Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
            continue
        }
        foreach ($operation in @("read", "write", "delete")) {
            $mutationValue = Get-PropertyValue $mutationContract $operation
            $operationReachability = Get-PropertyValue $reachability $operation
            $status = Get-PropertyValue $operationReachability "status"
            $caller = Get-PropertyValue $operationReachability "caller"
            if ($mutationValue -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$mutationValue) -or
                -not (Test-ExactOrdinalSet @(Get-PropertyNames $operationReachability) @("status", "caller")) -or
                $status -isnot [string] -or $allowedReachability -cnotcontains [string]$status -or
                $caller -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$caller)) {
                Add-Failure $Failures "P0A1-DATA-FIXTURE-CONTRACT"
            }
        }
    }

    $contracts = Get-DataTargetContracts $fixture
    $applicationOwnedIds = @($contracts.Keys | Where-Object {
            $contracts[$_].Ownership -ceq "application"
        })
    $externalReadOnlyIds = @($contracts.Keys | Where-Object {
            $contracts[$_].Ownership -cne "application" -and $contracts[$_].Access -ceq "read-only"
        })
    $currentWritableIds = @($contracts.Keys | Where-Object {
            [string]$contracts[$_].Lifecycle -clike "current-production-*"
        })
    $latentWritableIds = @($contracts.Keys | Where-Object {
            $contracts[$_].Lifecycle -ceq "latent-writable-currently-read-only"
        })
    if ($contracts.Count -ne 16 -or
        @($contracts.Values | Where-Object { -not $_.Valid }).Count -ne 0 -or
        -not (Test-ExactOrdinalSet $applicationOwnedIds $expectedApplicationOwnedTargetIds) -or
        -not (Test-ExactOrdinalSet $externalReadOnlyIds $expectedExternalReadOnlyTargetIds) -or
        -not (Test-ExactOrdinalSet $currentWritableIds $expectedCurrentWritableTargetIds) -or
        -not (Test-ExactOrdinalSet $latentWritableIds $expectedLatentWritableTargetIds)) {
        Add-Failure $Failures "P0A1-DATA-TARGET-CONTRACT"
    }
}

function Test-PersistedDataContract {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $inventories = Get-PropertyValue $Specification "inventories"
    $persistedData = @(Get-ArrayProperty $inventories "persistedData")
    $contracts = Get-DataTargetContracts $script:liveContext.Fixtures["P0A1-DATA-V5"]
    if ($persistedData.Count -ne 16 -or
        -not (Test-ExactOrdinalSet @(Get-ObjectIds $persistedData) $expectedPersistedDataTargetIds)) {
        Add-Failure $Failures "P0A1-DATA-TARGET-COVERAGE"
    }
    foreach ($targetId in $expectedPersistedDataTargetIds) {
        $records = @($persistedData | Where-Object { [string](Get-PropertyValue $_ "id") -ceq $targetId })
        $expected = if ($contracts.Contains($targetId)) { $contracts[$targetId] } else { $null }
        if ($records.Count -ne 1 -or $null -eq $expected) {
            Add-Failure $Failures "P0A1-DATA-TARGET-CONTRACT"
            continue
        }
        $record = $records[0]
        if (-not (Test-HasProperties $record @(
                    "id", "ownership", "access", "lifecycle", "path", "pathSemantics", "sourceLocators"
                )) -or
            [string](Get-PropertyValue $record "ownership") -cne $expected.Ownership -or
            [string](Get-PropertyValue $record "access") -cne $expected.Access -or
            [string](Get-PropertyValue $record "lifecycle") -cne $expected.Lifecycle -or
            [string](Get-PropertyValue $record "path") -cne $expected.Path -or
            -not (Test-ExactPathSemantics (Get-PropertyValue $record "pathSemantics") $expected.PathSemantics) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $record "sourceLocators") $expected.SourceLocators)) {
            Add-Failure $Failures "P0A1-DATA-TARGET-CONTRACT"
        }
    }
}

function Test-Boundaries {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $boundaries = @(Get-ArrayProperty $Specification "boundaries")
    $boundaryIds = @(Get-ObjectIds $boundaries)
    if (-not (Test-ExactOrdinalSet $boundaryIds $expectedBoundaryIds)) {
        Add-Failure $Failures "P0A1-PB-COVERAGE"
        return
    }

    $inventories = Get-PropertyValue $Specification "inventories"
    $componentIds = @(Get-ObjectIds @(Get-ArrayProperty $inventories "components"))
    $behaviorIds = @(Get-ObjectIds @(Get-ArrayProperty $inventories "publicBehaviors"))
    $dataIds = @(Get-ObjectIds @(Get-ArrayProperty $inventories "persistedData"))
    $integrationIds = @(Get-ObjectIds @(Get-ArrayProperty $inventories "integrationBoundaries"))
    $journeyIds = @(Get-ObjectIds @(Get-ArrayProperty $inventories "windowsJourneys"))
    $laneIds = @(Get-ObjectIds @(Get-ArrayProperty $Specification "qualificationLanes"))
    $artifactIds = @(Get-ObjectIds @(Get-ArrayProperty $Specification "artifacts"))
    $gapIds = @(Get-ObjectIds @(Get-ArrayProperty $Specification "knownGaps"))
    $oracleIds = @(Get-ObjectIds @(Get-ArrayProperty $script:liveContext.Fixtures["P0A1-ORACLES-V1"] "oracles"))
    $requiredProperties = @(
        "id", "title", "preserve", "replaceOrGap", "sourceLocators", "componentIds",
        "behaviorIds", "dataIds", "integrationIds", "journeyIds", "oracleIds", "artifactIds",
        "laneIds", "knownGapIds"
    )

    foreach ($boundary in $boundaries) {
        if (-not (Test-HasProperties $boundary $requiredProperties)) {
            Add-Failure $Failures "P0A1-BOUNDARY-SHAPE"
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string](Get-PropertyValue $boundary "title")) -or
            @(Get-ArrayProperty $boundary "sourceLocators").Count -eq 0 -or
            @(Get-ArrayProperty $boundary "componentIds").Count -eq 0 -or
            @(Get-ArrayProperty $boundary "behaviorIds").Count -eq 0 -or
            @(Get-ArrayProperty $boundary "laneIds").Count -eq 0) {
            Add-Failure $Failures "P0A1-BOUNDARY-COVERAGE"
        }
        if (-not (Test-IsSubset @(Get-ArrayProperty $boundary "componentIds") $componentIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "behaviorIds") $behaviorIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "dataIds") $dataIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "integrationIds") $integrationIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "journeyIds") $journeyIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "oracleIds") $oracleIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "artifactIds") $artifactIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "laneIds") $laneIds) -or
            -not (Test-IsSubset @(Get-ArrayProperty $boundary "knownGapIds") $gapIds)) {
            Add-Failure $Failures "P0A1-BOUNDARY-LINK"
        }
        $expectedBoundaryArtifactIds = @($expectedFixtureArtifacts.Keys | Where-Object {
            @($expectedFixtureArtifacts[$_].BoundaryIds) -ccontains [string]$boundary.id
        })
        $expectedBoundaryLaneIds = @($expectedLaneIds | Where-Object {
            @(Get-ExpectedLaneBehaviors $_) -ccontains [string]$boundary.id
        })
        if (-not (Test-ExactOrdinalSet @(Get-ArrayProperty $boundary "artifactIds") $expectedBoundaryArtifactIds) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $boundary "laneIds") $expectedBoundaryLaneIds)) {
            Add-Failure $Failures "P0A1-BOUNDARY-LINK"
        }
    }
}

function Test-BoundaryDataLinks {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $boundaries = @(Get-ArrayProperty $Specification "boundaries")
    $contracts = Get-DataTargetContracts $script:liveContext.Fixtures["P0A1-DATA-V5"]
    foreach ($boundaryId in $expectedBoundaryIds) {
        $matches = @($boundaries | Where-Object {
                [string](Get-PropertyValue $_ "id") -ceq $boundaryId
            })
        $expectedDataIds = @($expectedPersistedDataTargetIds | Where-Object {
                $contracts.Contains($_) -and @($contracts[$_].BoundaryIds) -ccontains $boundaryId
            })
        if ($matches.Count -ne 1 -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $matches[0] "dataIds") $expectedDataIds)) {
            Add-Failure $Failures "P0A1-BOUNDARY-DATA-LINK"
        }
    }
}

function Get-DispositionRecordsIdentity {
    param([object]$Traceability)

    $fields = @(
        "id", "mapId", "currentStatus", "disposition", "proposedDisposition",
        "approvalId", "approvalStatus", "baselineTreatment", "sourceTextSha256"
    )
    $recordSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in @(Get-ArrayProperty $Traceability "entries")) {
        if ([string](Get-PropertyValue $entry "namespace") -cne "CURRENT") { continue }
        $values = foreach ($field in $fields) {
            $value = Get-PropertyValue $entry $field
            if ($null -eq $value) { "" } else { [string]$value }
        }
        [void]$recordSet.Add([string]::Join("|", $values))
    }
    $records = @($recordSet)
    [Array]::Sort($records, [StringComparer]::Ordinal)
    return [PSCustomObject]@{
        Count = $records.Count
        Sha256 = Get-BytesSha256 ([Text.UTF8Encoding]::new($false).GetBytes(
            [string]::Join("`n", $records)
        ))
    }
}

function Test-TraceabilityBinding {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $binding = Get-PropertyValue $Specification "traceability"
    $requiredProperties = @(
        "path", "sha256", "entryCount", "currentEntryCount", "dispositionMapId",
        "recordsSha256", "recordsHashMethod", "boundaryIds", "requirementIds",
        "previousTraceability"
    )
    if (-not (Test-HasProperties $binding $requiredProperties)) {
        Add-Failure $Failures "P0A1-TRACEABILITY-SHAPE"
        Add-Failure $Failures "P0A1-REQMAP"
        Add-Failure $Failures "P0A1-TRACE-OWNER"
        return
    }

    $manifestRequirements = @(Get-ArrayProperty $script:liveContext.Manifest "requirementIds" | ForEach-Object {
            [string]$_
        })
    if (-not (Test-ExactOrdinalSet @($binding.requirementIds | ForEach-Object { [string]$_ }) $manifestRequirements) -or
        -not (Test-ExactOrdinalSet $manifestRequirements $expectedManifestRequirementIds) -or
        @(Get-ArrayProperty $binding "requirementIds").Count -ne 34) {
        Add-Failure $Failures "P0A1-REQUIREMENT-COVERAGE"
    }
    if (-not (Test-ExactOrdinalSet @($binding.boundaryIds | ForEach-Object { [string]$_ }) $expectedBoundaryIds)) {
        Add-Failure $Failures "P0A1-PB-COVERAGE"
    }

    $traceability = $script:liveContext.Traceability
    $currentEntries = @($traceability.entries | Where-Object { $_.namespace -ceq "CURRENT" })
    $dispositionMaps = @($traceability.dispositionMaps)
    $map = @($dispositionMaps | Where-Object { $_.id -ceq "REQMAP-CURRENT-V1" })
    $previousTraceability = Get-PropertyValue $binding "previousTraceability"
    $recordsHashMethod = Get-PropertyValue $binding "recordsHashMethod"
    $entrySelector = Get-PropertyValue $recordsHashMethod "entrySelector"
    $recordsIdentity = Get-DispositionRecordsIdentity $traceability
    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $recordsHashMethod) @(
                "entrySelector", "fields", "nullOrMissingValue", "fieldSeparator",
                "uniqueRecords", "recordSort", "recordSeparator", "trailingRecordSeparator",
                "encoding", "bom", "digestAlgorithm", "digestEncoding"
            )) -or
        -not (Test-ExactOrdinalSet @(Get-PropertyNames $entrySelector) @(
                "collection", "field", "equals"
            )) -or
        [string](Get-PropertyValue $entrySelector "collection") -cne "entries" -or
        [string](Get-PropertyValue $entrySelector "field") -cne "namespace" -or
        [string](Get-PropertyValue $entrySelector "equals") -cne "CURRENT" -or
        -not (Test-ExactOrdinalSet @(Get-ArrayProperty $recordsHashMethod "fields") @(
                "id", "mapId", "currentStatus", "disposition", "proposedDisposition",
                "approvalId", "approvalStatus", "baselineTreatment", "sourceTextSha256"
            )) -or
        [string](Get-PropertyValue $recordsHashMethod "nullOrMissingValue") -cne "" -or
        [string](Get-PropertyValue $recordsHashMethod "fieldSeparator") -cne "|" -or
        (Get-PropertyValue $recordsHashMethod "uniqueRecords") -isnot [bool] -or
        (Get-PropertyValue $recordsHashMethod "uniqueRecords") -ne $true -or
        [string](Get-PropertyValue $recordsHashMethod "recordSort") -cne "ordinal-ascending" -or
        [string](Get-PropertyValue $recordsHashMethod "recordSeparator") -cne "LF" -or
        (Get-PropertyValue $recordsHashMethod "trailingRecordSeparator") -isnot [bool] -or
        (Get-PropertyValue $recordsHashMethod "trailingRecordSeparator") -ne $false -or
        [string](Get-PropertyValue $recordsHashMethod "encoding") -cne "UTF-8" -or
        (Get-PropertyValue $recordsHashMethod "bom") -isnot [bool] -or
        (Get-PropertyValue $recordsHashMethod "bom") -ne $false -or
        [string](Get-PropertyValue $recordsHashMethod "digestAlgorithm") -cne "SHA-256" -or
        [string](Get-PropertyValue $recordsHashMethod "digestEncoding") -cne "lowercase-hex" -or
        [long](Get-PropertyValue $recordsIdentity "Count") -ne 114 -or
        [string](Get-PropertyValue $recordsIdentity "Sha256") -cne $frozenDispositionRecordsSha256) {
        Add-Failure $Failures "P0A1-REQMAP"
    }
    if ([string](Get-PropertyValue $binding "path") -cne "docs/verification/traceability-v2.yml" -or
        [string](Get-PropertyValue $binding "sha256") -cne $frozenTraceabilitySha256 -or
        $script:liveContext.TraceabilitySha256 -cne $frozenTraceabilitySha256 -or
        -not (Test-ExactOrdinalSet @(Get-PropertyNames $previousTraceability) @("path", "sha256")) -or
        [string](Get-PropertyValue $previousTraceability "path") -cne "docs/verification/traceability-v1.yml" -or
        [string](Get-PropertyValue $previousTraceability "sha256") -cne $frozenPredecessorTraceabilitySha256 -or
        $script:liveContext.PredecessorTraceabilitySha256 -cne $frozenPredecessorTraceabilitySha256 -or
        [string](Get-PropertyValue $traceability "baselineSha") -cne $frozenTraceabilityBaselineSha -or
        [string](Get-PropertyValue $traceability "currentRequirementsOriginSha") -cne
            $frozenCurrentRequirementsOriginSha -or
        [long]$binding.entryCount -ne @($traceability.entries).Count -or
        [long]$binding.currentEntryCount -ne 114 -or
        $currentEntries.Count -ne 114 -or
        $map.Count -ne 1 -or
        [string]$binding.dispositionMapId -cne "REQMAP-CURRENT-V1" -or
        [long]$map[0].entryCount -ne 114 -or
        [string]$binding.recordsSha256 -cne $frozenDispositionRecordsSha256 -or
        [string]$map[0].recordsSha256 -cne $frozenDispositionRecordsSha256) {
        Add-Failure $Failures "P0A1-REQMAP"
        Add-Failure $Failures "P0A1-TRACE-OWNER"
    }

    foreach ($rowId in $expectedTraceRows.Keys) {
        $expectedRow = $expectedTraceRows[$rowId]
        $rows = @($traceability.testCatalog | Where-Object { [string]$_.id -ceq $rowId })
        if ($rows.Count -ne 1 -or
            [string](Get-PropertyValue $rows[0] "ownerStep") -cne $expectedRow.OwnerStep -or
            [string](Get-PropertyValue $rows[0] "lane") -cne $expectedRow.Lane -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $rows[0] "requirementIds") $expectedRow.RequirementIds) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $rows[0] "behaviorIds") $expectedRow.BehaviorIds)) {
            Add-Failure $Failures "P0A1-TRACE-OWNER"
        }
    }
}

function Test-TraceOwnerContracts {
    param([Collections.Generic.List[string]]$Failures)

    $entries = @(Get-ArrayProperty $script:liveContext.Traceability "entries")
    foreach ($requirementId in $expectedTraceEntryOwnerTestIds.Keys) {
        $matches = @($entries | Where-Object { [string](Get-PropertyValue $_ "id") -ceq $requirementId })
        if ($matches.Count -ne 1 -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $matches[0] "testIds") `
                $expectedTraceEntryOwnerTestIds[$requirementId])) {
            Add-Failure $Failures "P0A1-TRACE-OWNER"
        }
    }

    foreach ($requirementId in $expectedFutureApprovalContracts.Keys) {
        $matches = @($entries | Where-Object { [string](Get-PropertyValue $_ "id") -ceq $requirementId })
        $expected = $expectedFutureApprovalContracts[$requirementId]
        if ($matches.Count -ne 1 -or
            [string](Get-PropertyValue $matches[0] "approvalId") -cne $expected.ApprovalId -or
            [string](Get-PropertyValue $matches[0] "approvalStatus") -cne "pending" -or
            [string](Get-PropertyValue $matches[0] "proposedDisposition") -cne "defer" -or
            [string](Get-PropertyValue $matches[0] "baselineTreatment") -cne $expected.BaselineTreatment -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $matches[0] "testIds") $expected.TestIds)) {
            Add-Failure $Failures "P0A1-TRACE-PENDING-APPROVAL"
        }
    }
}

function Test-ManifestInvalidationRecord {
    param(
        [object]$Record,
        [string]$RecordSha256,
        [string]$ExpectedRecordSha256,
        [string]$ExpectedRecordId,
        [string]$ExpectedManifestId,
        [string]$ExpectedManifestPath,
        [string]$ExpectedManifestSha256,
        [string]$ExpectedReplacementId,
        [Collections.Generic.List[string]]$Failures
    )

    $invalidatedArtifactFullPath = Resolve-RepositoryPath $ExpectedManifestPath
    $timestampText = [string](Get-PropertyValue $Record "invalidatedAt")
    $timestamp = [DateTimeOffset]::MinValue
    $timestampValid = $timestampText -cmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$' -and
        [DateTimeOffset]::TryParse(
            $timestampText,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal,
            [ref]$timestamp
        )
    if ($RecordSha256 -cne $ExpectedRecordSha256 -or
        $null -eq $invalidatedArtifactFullPath -or
        (Get-RawFileSha256 $invalidatedArtifactFullPath) -cne $ExpectedManifestSha256 -or
        -not (Test-ExactOrdinalSet @(Get-PropertyNames $Record) @(
                "schemaVersion", "recordType", "recordId", "invalidatedManifestId",
                "frozenArtifactPath", "frozenArtifactSha256", "replacementManifestId",
                "invalidatedAt", "reason", "reviewer"
            )) -or
        [long](Get-PropertyValue $Record "schemaVersion") -ne 1 -or
        [string](Get-PropertyValue $Record "recordType") -cne "manifest-invalidation" -or
        [string](Get-PropertyValue $Record "recordId") -cne $ExpectedRecordId -or
        [string](Get-PropertyValue $Record "invalidatedManifestId") -cne $ExpectedManifestId -or
        [string](Get-PropertyValue $Record "frozenArtifactPath") -cne $ExpectedManifestPath -or
        [string](Get-PropertyValue $Record "frozenArtifactSha256") -cne $ExpectedManifestSha256 -or
        [string](Get-PropertyValue $Record "replacementManifestId") -cne $ExpectedReplacementId -or
        -not $timestampValid -or
        [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $Record "reason")) -or
        [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $Record "reviewer"))) {
        Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
    }
    return $timestamp
}

function Test-ManifestContract {
    param([Collections.Generic.List[string]]$Failures)

    $manifest = $script:liveContext.Manifest
    $probe = @(Get-ArrayProperty $manifest "probes")
    $lanes = @(Get-ArrayProperty $manifest "lanes")
    if ($script:liveContext.ManifestSha256 -cne $frozenManifestSha256 -or
        [long](Get-PropertyValue $manifest "schemaVersion") -ne 1 -or
        [string](Get-PropertyValue $manifest "manifestType") -cne "risk-lane" -or
        [string](Get-PropertyValue $manifest "manifestId") -cne "P0A.1-v9" -or
        [long](Get-PropertyValue $manifest "revision") -ne 9 -or
        [string](Get-PropertyValue $manifest "previousManifestId") -cne "P0A.1-v8" -or
        $null -ne (Get-PropertyValue $manifest "invalidationReason") -or
        [string](Get-PropertyValue $manifest "stepId") -cne "P0A.1" -or
        [string](Get-PropertyValue $manifest "status") -cne "frozen-before-red" -or
        [string](Get-PropertyValue $manifest "baselineSha") -cne $frozenBaselineSha -or
        $probe.Count -ne 1 -or $lanes.Count -ne 1) {
        Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
    }

    $manifestThresholds = Get-PropertyValue $manifest "thresholds"
    $probeThresholds = if ($probe.Count -eq 1) { Get-PropertyValue $probe[0] "thresholds" } else { $null }
    foreach ($thresholds in @($manifestThresholds, $probeThresholds)) {
        if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $thresholds) @($expectedManifestThresholds.Keys))) {
            Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
            continue
        }
        foreach ($name in $expectedManifestThresholds.Keys) {
            if ([long](Get-PropertyValue $thresholds $name) -ne [long]$expectedManifestThresholds[$name]) {
                Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
            }
        }
    }

    if ($probe.Count -eq 1) {
        if ([string](Get-PropertyValue $probe[0] "id") -cne "P0A.1-V-STATIC-STATIC-CONTRACT" -or
            [string](Get-PropertyValue $probe[0] "command") -cne
                "./tools/verification/Test-PreservationSpecification.ps1" -or
            [long](Get-PropertyValue $probe[0] "minimumDiscovery") -ne 8 -or
            [string](Get-PropertyValue $probe[0] "redOracle") -cne $expectedManifestRedOracle -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $probe[0] "laneIds") @("V-STATIC")) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $probe[0] "environmentIds") @(
                    "ENV-WINDOWS-LOCAL", "ENV-GHA-UBUNTU"
                )) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $probe[0] "fixtureIds") @(
                    $expectedFixtureArtifacts.Keys
                ))) {
            Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
        }
    }
    if (-not (Test-ExactOrdinalSet @(Get-ArrayProperty $manifest "requirementIds") `
            $expectedManifestRequirementIds)) {
        Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
    }

    $manifestEnvironments = @(Get-ArrayProperty $manifest "environments")
    if (-not (Test-ExactOrdinalSet @(Get-ObjectIds $manifestEnvironments) @($expectedManifestEnvironments.Keys)) -or
        $manifestEnvironments.Count -ne 5) {
        Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
    }
    foreach ($environmentId in $expectedManifestEnvironments.Keys) {
        $matches = @($manifestEnvironments | Where-Object { [string]$_.id -ceq $environmentId })
        $expected = $expectedManifestEnvironments[$environmentId]
        if ($matches.Count -ne 1 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $matches[0]) @("id", "os", "shell", "purpose")) -or
            [string](Get-PropertyValue $matches[0] "os") -cne $expected.Os -or
            [string](Get-PropertyValue $matches[0] "shell") -cne $expected.Shell -or
            [string](Get-PropertyValue $matches[0] "purpose") -cne $expected.Purpose) {
            Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
        }
    }

    $manifestFixtures = @(Get-ArrayProperty $manifest "fixtures")
    if (-not (Test-ExactOrdinalSet @(Get-ObjectIds $manifestFixtures) @($expectedFixtureArtifacts.Keys)) -or
        $manifestFixtures.Count -ne 4) {
        Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
    }
    foreach ($fixtureId in $expectedFixtureArtifacts.Keys) {
        $matches = @($manifestFixtures | Where-Object { [string]$_.id -ceq $fixtureId })
        $expected = $expectedFixtureArtifacts[$fixtureId]
        if ($matches.Count -ne 1 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $matches[0]) @("id", "path", "sha256")) -or
            [string](Get-PropertyValue $matches[0] "path") -cne $expected.Path -or
            [string](Get-PropertyValue $matches[0] "sha256") -cne $expected.Sha256) {
            Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
        }
    }

    $v1InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V1Invalidation `
        $script:liveContext.V1InvalidationSha256 `
        $frozenV1InvalidationRecordSha256 `
        "P0A.1-v1-invalidated-by-v2" `
        "P0A.1-v1" `
        "docs/verification/manifests/P0A.1-v1.yml" `
        $invalidatedV1ManifestSha256 `
        "P0A.1-v2" `
        $Failures
    $v2InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V2Invalidation `
        $script:liveContext.V2InvalidationSha256 `
        $frozenV2InvalidationRecordSha256 `
        "P0A.1-v2-invalidated-by-v3" `
        "P0A.1-v2" `
        "docs/verification/manifests/P0A.1-v2.yml" `
        $invalidatedV2ManifestSha256 `
        "P0A.1-v3" `
        $Failures
    $v3InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V3Invalidation `
        $script:liveContext.V3InvalidationSha256 `
        $frozenV3InvalidationRecordSha256 `
        "P0A.1-v3-invalidated-by-v4" `
        "P0A.1-v3" `
        "docs/verification/manifests/P0A.1-v3.yml" `
        $invalidatedV3ManifestSha256 `
        "P0A.1-v4" `
        $Failures
    $v4InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V4Invalidation `
        $script:liveContext.V4InvalidationSha256 `
        $frozenV4InvalidationRecordSha256 `
        "P0A.1-v4-invalidated-by-v5" `
        "P0A.1-v4" `
        "docs/verification/manifests/P0A.1-v4.yml" `
        $invalidatedV4ManifestSha256 `
        "P0A.1-v5" `
        $Failures
    $v5InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V5ReplacementInvalidation `
        $script:liveContext.V5ReplacementInvalidationSha256 `
        $frozenV5ReplacementInvalidationRecordSha256 `
        "P0A.1-v5-invalidated-by-v7" `
        "P0A.1-v5" `
        "docs/verification/manifests/P0A.1-v5.yml" `
        $invalidatedV5ManifestSha256 `
        "P0A.1-v7" `
        $Failures
    $v6InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V6Invalidation `
        $script:liveContext.V6InvalidationSha256 `
        $frozenV6InvalidationRecordSha256 `
        "P0A.1-v6-invalidated-by-v7" `
        "P0A.1-v6" `
        "docs/verification/manifests/P0A.1-v6.yml" `
        $invalidatedV6ManifestSha256 `
        "P0A.1-v7" `
        $Failures
    $v7InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V7Invalidation `
        $script:liveContext.V7InvalidationSha256 `
        $frozenV7InvalidationRecordSha256 `
        "P0A.1-v7-invalidated-by-v8" `
        "P0A.1-v7" `
        "docs/verification/manifests/P0A.1-v7.yml" `
        $invalidatedV7ManifestSha256 `
        "P0A.1-v8" `
        $Failures
    $v8InvalidatedAt = Test-ManifestInvalidationRecord `
        $script:liveContext.V8Invalidation `
        $script:liveContext.V8InvalidationSha256 `
        $frozenV8InvalidationRecordSha256 `
        "P0A.1-v8-invalidated-by-v9" `
        "P0A.1-v8" `
        "docs/verification/manifests/P0A.1-v8.yml" `
        $invalidatedV8ManifestSha256 `
        "P0A.1-v9" `
        $Failures
    if ($v1InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v2InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v3InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v4InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v5InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v6InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v7InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        $v8InvalidatedAt -eq [DateTimeOffset]::MinValue -or
        [string](Get-PropertyValue $script:liveContext.V7Invalidation "reviewer") -cne
            "clean-room-preservation-reviewer-04" -or
        [string](Get-PropertyValue $script:liveContext.V8Invalidation "reviewer") -cne
            "ci-mapper-source-identity-reviewer-01" -or
        $v1InvalidatedAt -ge $v2InvalidatedAt -or
        $v2InvalidatedAt -ge $v3InvalidatedAt -or
        $v3InvalidatedAt -ge $v4InvalidatedAt -or
        $v4InvalidatedAt -ge $v5InvalidatedAt -or
        $v4InvalidatedAt -ge $v6InvalidatedAt -or
        $v5InvalidatedAt -ge $v7InvalidatedAt -or
        $v6InvalidatedAt -ge $v7InvalidatedAt -or
        $v7InvalidatedAt -ge $v8InvalidatedAt) {
        Add-Failure $Failures "P0A1-MANIFEST-CONTRACT"
    }
}

function Test-SourceBindings {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $declaredSources = @(Get-ArrayProperty $Specification "sources")
    $traceSources = @($script:liveContext.Traceability.sources)
    $sourceHashMethod = Get-PropertyValue $Specification "sourceHashMethod"
    $sourceMethodProperties = @(Get-PropertyNames $sourceHashMethod)
    if (-not (Test-ExactOrdinalSet $sourceMethodProperties @(
                "version", "encoding", "lineEndingNormalization", "normalizedCheckboxText", "digest"
            )) -or
        [long](Get-PropertyValue $sourceHashMethod "version") -ne 1 -or
        [string](Get-PropertyValue $sourceHashMethod "encoding") -cne "UTF-8 without BOM" -or
        [string](Get-PropertyValue $sourceHashMethod "lineEndingNormalization") -cne "CRLF and CR to LF" -or
        [string](Get-PropertyValue $sourceHashMethod "normalizedCheckboxText") -cne
            "Replace leading - [x] and - [X] with - [ ]" -or
        [string](Get-PropertyValue $sourceHashMethod "digest") -cne "SHA-256 lowercase hexadecimal") {
        Add-Failure $Failures "P0A1-SOURCE-METHOD"
    }
    if (-not (Test-ExactOrdinalSet @(Get-ObjectIds $declaredSources) @($expectedSources.Keys)) -or
        -not (Test-ExactOrdinalSet @(Get-ObjectIds $traceSources) @($expectedSources.Keys))) {
        Add-Failure $Failures "P0A1-SOURCE-BINDING"
        return
    }
    foreach ($sourceId in $expectedSources.Keys) {
        $expectedSource = $expectedSources[$sourceId]
        $declaredMatches = @($declaredSources | Where-Object { [string]$_.id -ceq $sourceId })
        $traceMatches = @($traceSources | Where-Object { [string]$_.id -ceq $sourceId })
        $fullPath = Resolve-RepositoryPath $expectedSource.Path
        $liveHash = if ($null -eq $fullPath) {
            $null
        } else {
            Get-NormalizedTextSha256 $fullPath $expectedSource.HashMode
        }
        if ($declaredMatches.Count -ne 1 -or $traceMatches.Count -ne 1 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $declaredMatches[0]) @(
                    "id", "path", "revision", "hashMode", "sha256"
                )) -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $traceMatches[0]) @(
                    "id", "path", "revision", "hashMode", "sha256"
                )) -or
            [string](Get-PropertyValue $declaredMatches[0] "hashMode") -cne $expectedSource.HashMode -or
            [string](Get-PropertyValue $traceMatches[0] "hashMode") -cne $expectedSource.HashMode) {
            Add-Failure $Failures "P0A1-SOURCE-METHOD"
        }
        if ($declaredMatches.Count -ne 1 -or $traceMatches.Count -ne 1 -or
            [string](Get-PropertyValue $declaredMatches[0] "path") -cne $expectedSource.Path -or
            [string](Get-PropertyValue $declaredMatches[0] "revision") -cne $expectedSource.Revision -or
            [string](Get-PropertyValue $declaredMatches[0] "sha256") -cne $expectedSource.Sha256 -or
            [string](Get-PropertyValue $traceMatches[0] "path") -cne $expectedSource.Path -or
            [string](Get-PropertyValue $traceMatches[0] "revision") -cne $expectedSource.Revision -or
            [string](Get-PropertyValue $traceMatches[0] "sha256") -cne $expectedSource.Sha256 -or
            $liveHash -cne $expectedSource.Sha256) {
            Add-Failure $Failures "P0A1-SOURCE-HASH"
        }
    }
}

function Test-ProductionBaseline {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $baseline = Get-PropertyValue $Specification "baseline"
    if (-not (Test-HasProperties $baseline @(
                "commitSha", "currentRequirementsOriginSha", "productionRootIdentityMethod",
                "productionRoots"
            )) -or
        [string](Get-PropertyValue $baseline "commitSha") -cne $frozenBaselineSha -or
        [string](Get-PropertyValue $baseline "currentRequirementsOriginSha") -cne
            $frozenCurrentRequirementsOriginSha) {
        Add-Failure $Failures "P0A1-BASELINE-IDENTITY"
    }

    $identityMethod = Get-PropertyValue $baseline "productionRootIdentityMethod"
    $identityMethodProperties = @(Get-PropertyNames $identityMethod)
    $excludeReparsePoints = Get-PropertyValue $identityMethod "excludeReparsePoints"
    if (-not (Test-ExactOrdinalSet $identityMethodProperties @(
                "version", "excludeReparsePoints", "excludedDirectoryNames", "excludedFileSuffixes",
                "recordFormat", "pathSeparator", "sort", "join", "encoding", "digest"
            )) -or
        [long](Get-PropertyValue $identityMethod "version") -ne 1 -or
        $excludeReparsePoints -isnot [bool] -or $excludeReparsePoints -ne $true -or
        -not (Test-ExactOrdinalSet @(Get-ArrayProperty $identityMethod "excludedDirectoryNames") @(
                "bin", "obj", "__pycache__", ".pytest_cache"
            )) -or
        -not (Test-ExactOrdinalSet @(Get-ArrayProperty $identityMethod "excludedFileSuffixes") @(".pyc")) -or
        [string](Get-PropertyValue $identityMethod "recordFormat") -cne
            "relative/path|byteLength|lowercaseRawSha256" -or
        [string](Get-PropertyValue $identityMethod "pathSeparator") -cne "/" -or
        [string](Get-PropertyValue $identityMethod "sort") -cne "StringComparer.Ordinal" -or
        [string](Get-PropertyValue $identityMethod "join") -cne "LF without trailing delimiter" -or
        [string](Get-PropertyValue $identityMethod "encoding") -cne "UTF-8 without BOM" -or
        [string](Get-PropertyValue $identityMethod "digest") -cne "SHA-256 lowercase hexadecimal") {
        Add-Failure $Failures "P0A1-PRODUCTION-ROOT-METHOD"
    }

    $roots = @(Get-ArrayProperty $baseline "productionRoots")
    $rootPaths = @($roots | ForEach-Object { [string]$_.path })
    if (-not (Test-ExactOrdinalSet $rootPaths @($expectedProductionRoots.Keys)) -or $roots.Count -ne 2) {
        Add-Failure $Failures "P0A1-PRODUCTION-ROOT"
        return
    }
    $totalFiles = 0
    foreach ($root in $roots) {
        $path = [string]$root.path
        $expected = $expectedProductionRoots[$path]
        $live = $script:liveContext.ProductionRoots[$path]
        if ($null -eq $live -or
            [long]$root.fileCount -ne [long]$expected.FileCount -or
            [string]$root.sha256 -cne [string]$expected.Sha256 -or
            [long]$live.FileCount -ne [long]$expected.FileCount -or
            [string]$live.Sha256 -cne [string]$expected.Sha256) {
            Add-Failure $Failures "P0A1-PRODUCTION-ROOT"
        }
        $totalFiles += [long]$root.fileCount
    }
    if ($totalFiles -ne 140) { Add-Failure $Failures "P0A1-PRODUCTION-FILE-COUNT" }
}

function Test-ArtifactBindings {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $artifacts = @(Get-ArrayProperty $Specification "artifacts")
    if (-not (Test-ExactOrdinalSet @(Get-ObjectIds $artifacts) @($expectedFixtureArtifacts.Keys)) -or
        $artifacts.Count -ne 4) {
        Add-Failure $Failures "P0A1-ARTIFACT-COVERAGE"
        Add-Failure $Failures "P0A1-FIXTURE-HASH"
        return
    }

    foreach ($artifact in $artifacts) {
        if (-not (Test-HasProperties $artifact @("id", "path", "sha256", "kind", "boundaryIds"))) {
            Add-Failure $Failures "P0A1-ARTIFACT-SHAPE"
            continue
        }
        $id = [string]$artifact.id
        $expected = $expectedFixtureArtifacts[$id]
        $declaredPath = [string]$artifact.path
        $fullPath = if ($declaredPath -ceq [string]$expected.Path) {
            Resolve-RepositoryPath ([string]$expected.Path)
        } else {
            $null
        }
        $liveHash = if ($null -eq $fullPath) { $null } else { Get-RawFileSha256 $fullPath }
        $manifestFixture = @($script:liveContext.Manifest.fixtures | Where-Object { $_.id -ceq $id })
        if ($declaredPath -cne [string]$expected.Path -or
            [string]$artifact.sha256 -cne [string]$expected.Sha256 -or
            $liveHash -cne [string]$expected.Sha256 -or
            $manifestFixture.Count -ne 1 -or
            [string]$manifestFixture[0].path -cne [string]$expected.Path -or
            [string]$manifestFixture[0].sha256 -cne [string]$expected.Sha256) {
            Add-Failure $Failures "P0A1-FIXTURE-HASH"
        }
        if (-not (Test-ExactOrdinalSet @(Get-ArrayProperty $artifact "boundaryIds") $expected.BoundaryIds)) {
            Add-Failure $Failures "P0A1-ARTIFACT-LINK"
        }

        $fixture = $script:liveContext.Fixtures[$id]
        $records = @(Get-ArrayProperty $fixture ([string]$expected.Collection))
        if ([long](Get-PropertyValue $fixture "schemaVersion") -ne [long]$expected.SchemaVersion -or
            [string](Get-PropertyValue $fixture "fixtureId") -cne $id -or
            $records.Count -ne [long]$expected.Count) {
            Add-Failure $Failures "P0A1-FIXTURE-SHAPE"
        }
        $recordIds = if ($id -ceq "P0A1-RESOURCES-V1") {
            @($records | ForEach-Object { [string](Get-PropertyValue $_ "path") })
        } else {
            @(Get-ObjectIds $records)
        }
        $uniqueRecordIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($recordId in $recordIds) {
            if ([string]::IsNullOrWhiteSpace($recordId) -or -not $uniqueRecordIds.Add($recordId)) {
                Add-Failure $Failures "P0A1-FIXTURE-IDENTITY"
            }
        }
        if ($id -cne "P0A1-RESOURCES-V1") {
            foreach ($record in $records) {
                if (-not (Test-IsSubset @(Get-ArrayProperty $record "boundaryIds") $expectedBoundaryIds) -or
                    @(Get-ArrayProperty $record "boundaryIds").Count -eq 0) {
                    Add-Failure $Failures "P0A1-FIXTURE-LINK"
                }
            }
        }
    }

    $resourceDefinition = $expectedFixtureArtifacts["P0A1-RESOURCES-V1"]
    $resourceFixturePath = Resolve-RepositoryPath ([string]$resourceDefinition.Path)
    if ($null -eq $resourceFixturePath -or
        (Get-RawFileSha256 $resourceFixturePath) -cne [string]$resourceDefinition.Sha256) {
        Add-Failure $Failures "P0A1-FIXTURE-HASH"
        return
    }
    $resources = @(Get-ArrayProperty $script:liveContext.Fixtures["P0A1-RESOURCES-V1"] "resources")
    if ($resources.Count -ne 11) { Add-Failure $Failures "P0A1-RESOURCE-COVERAGE" }
    foreach ($resource in $resources) {
        $fullPath = Resolve-RepositoryPath ([string]$resource.path)
        if ($null -eq $fullPath -or
            -not (Test-Path -LiteralPath $fullPath -PathType Leaf) -or
            [long](Get-Item -LiteralPath $fullPath).Length -ne [long]$resource.bytes -or
            (Get-RawFileSha256 $fullPath) -cne [string]$resource.sha256) {
            Add-Failure $Failures "P0A1-RESOURCE-HASH"
        }
    }
}

function Test-SemanticFixtures {
    param([Collections.Generic.List[string]]$Failures)

    $dataRecords = @(Get-ArrayProperty $script:liveContext.Fixtures["P0A1-DATA-V5"] "records")
    $positionRecords = @($dataRecords | Where-Object { [string]$_.id -ceq "DATA-CONFIG-POSITION-RESTART" })
    if ($positionRecords.Count -ne 1) {
        Add-Failure $Failures "P0A1-POSITION-CANARY"
    } else {
        $position = $positionRecords[0]
        $payload = Get-PropertyValue $position "payload"
        $expected = Get-PropertyValue $position "expected"
        $restores = Get-PropertyValue $expected "restoresWhenBothNonNegative"
        $absoluteCoordinates = Get-PropertyValue $expected "absoluteCoordinatesAreStableOracle"
        if (-not (Test-HasProperties $position @(
                    "id", "targetId", "boundaryIds", "ownership", "access", "lifecycle", "path",
                    "pathSemantics", "sourceLocators", "mutationContract", "reachability", "fixtureRole",
                    "contractRole", "completeness", "payload", "expected"
                )) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $position "boundaryIds") @("PB-003", "PB-008")) -or
            [string](Get-PropertyValue $position "path") -cne "%LOCALAPPDATA%/AemeathDesktopPet/config.json" -or
            [string](Get-PropertyValue $position "fixtureRole") -cne "position-restart-roundtrip-canary" -or
            [string](Get-PropertyValue $position "contractRole") -cne "serialize-deserialize-roundtrip" -or
            [string](Get-PropertyValue $position "completeness") -cne "targeted" -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $payload) @("lastX", "lastY")) -or
            [double](Get-PropertyValue $payload "lastX") -ne 320.5 -or
            [double](Get-PropertyValue $payload "lastY") -ne 240.25 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $expected) @(
                    "jsonNames", "restoresWhenBothNonNegative", "absoluteCoordinatesAreStableOracle"
                )) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $expected "jsonNames") @("lastX", "lastY")) -or
            $restores -isnot [bool] -or $restores -ne $true -or
            $absoluteCoordinates -isnot [bool] -or $absoluteCoordinates -ne $false) {
            Add-Failure $Failures "P0A1-POSITION-CANARY"
        }
    }

    $oracles = @(Get-ArrayProperty $script:liveContext.Fixtures["P0A1-ORACLES-V1"] "oracles")
    $boundsRecords = @($oracles | Where-Object { [string]$_.id -ceq "ORACLE-STATS-BOUNDS" })
    if ($boundsRecords.Count -ne 1) {
        Add-Failure $Failures "P0A1-STATS-LITERAL"
    } else {
        $bounds = $boundsRecords[0]
        $expected = Get-PropertyValue $bounds "expected"
        $mood = Get-PropertyValue $expected "mood"
        $energy = Get-PropertyValue $expected "energy"
        $affection = Get-PropertyValue $expected "affection"
        if ([string](Get-PropertyValue $bounds "kind") -cne "property" -or
            [string](Get-PropertyValue $bounds "source") -cne "src/AemeathDesktopPet/Models/AemeathStats.cs" -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $bounds "boundaryIds") @("PB-009")) -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $expected) @(
                    "minimum", "maximum", "offlineDecaySkipWhenHoursBelow", "mood", "energy", "affection"
                )) -or
            [double](Get-PropertyValue $expected "minimum") -ne 0 -or
            [double](Get-PropertyValue $expected "maximum") -ne 100 -or
            [double](Get-PropertyValue $expected "offlineDecaySkipWhenHoursBelow") -ne 0.1 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $mood) @(
                    "fastDecrementPerHour", "slowDecrementPerHour", "fastHours",
                    "fastStageInclusive", "floor"
                )) -or
            [double](Get-PropertyValue $mood "fastDecrementPerHour") -ne 5 -or
            [double](Get-PropertyValue $mood "slowDecrementPerHour") -ne 2 -or
            [double](Get-PropertyValue $mood "fastHours") -ne 4 -or
            (Get-PropertyValue $mood "fastStageInclusive") -isnot [bool] -or
            (Get-PropertyValue $mood "fastStageInclusive") -ne $true -or
            [double](Get-PropertyValue $mood "floor") -ne 30 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $energy) @(
                    "fastDecrementPerHour", "slowDecrementPerHour", "fastHours",
                    "fastStageInclusive", "floor"
                )) -or
            [double](Get-PropertyValue $energy "fastDecrementPerHour") -ne 3 -or
            [double](Get-PropertyValue $energy "slowDecrementPerHour") -ne 1 -or
            [double](Get-PropertyValue $energy "fastHours") -ne 6 -or
            (Get-PropertyValue $energy "fastStageInclusive") -isnot [bool] -or
            (Get-PropertyValue $energy "fastStageInclusive") -ne $true -or
            [double](Get-PropertyValue $energy "floor") -ne 20 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $affection) @(
                    "fastDecrementPerHour", "slowDecrementPerHour", "fastHours",
                    "fastStageInclusive", "floor"
                )) -or
            [double](Get-PropertyValue $affection "fastDecrementPerHour") -ne 1 -or
            [double](Get-PropertyValue $affection "slowDecrementPerHour") -ne 0.5 -or
            [double](Get-PropertyValue $affection "fastHours") -ne 12 -or
            (Get-PropertyValue $affection "fastStageInclusive") -isnot [bool] -or
            (Get-PropertyValue $affection "fastStageInclusive") -ne $true -or
            [double](Get-PropertyValue $affection "floor") -ne 40) {
            Add-Failure $Failures "P0A1-STATS-LITERAL"
        }
    }

    $timerRecords = @($oracles | Where-Object { [string]$_.id -ceq "ORACLE-STATS-TIMER" })
    if ($timerRecords.Count -ne 1) {
        Add-Failure $Failures "P0A1-STATS-LITERAL"
    } else {
        $timer = $timerRecords[0]
        $expected = Get-PropertyValue $timer "expected"
        $mood = Get-PropertyValue $expected "mood"
        if ([string](Get-PropertyValue $timer "kind") -cne "time" -or
            [string](Get-PropertyValue $timer "source") -cne "src/AemeathDesktopPet/Services/StatsService.cs" -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $timer "boundaryIds") @("PB-009")) -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $expected) @(
                    "activeDecayMinutes", "energyDelta", "mood"
                )) -or
            [double](Get-PropertyValue $expected "activeDecayMinutes") -ne 5 -or
            [double](Get-PropertyValue $expected "energyDelta") -ne -1 -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $mood) @(
                    "decreaseWhenAbove", "decreaseDelta", "increaseWhenBelow", "increaseDelta",
                    "noChangeRangeInclusive"
                )) -or
            [double](Get-PropertyValue $mood "decreaseWhenAbove") -ne 55 -or
            [double](Get-PropertyValue $mood "decreaseDelta") -ne -0.5 -or
            [double](Get-PropertyValue $mood "increaseWhenBelow") -ne 45 -or
            [double](Get-PropertyValue $mood "increaseDelta") -ne 0.5 -or
            (@(Get-ArrayProperty $mood "noChangeRangeInclusive") -join '|') -cne "45|55") {
            Add-Failure $Failures "P0A1-STATS-LITERAL"
        }
    }

    $protocols = @(Get-ArrayProperty $script:liveContext.Fixtures["P0A1-PROTOCOL-V3"] "contracts")
    $expectedSseContracts = [ordered]@{
        "PROTOCOL-SSE-TOKEN" = [PSCustomObject]@{
            BoundaryIds = @("PB-005", "PB-011", "PB-012")
            EventType = "token"
            RequiredPayload = @("type", "content")
            ConsumerOutcome = "not-qualified-compatible"
        }
        "PROTOCOL-SSE-DONE" = [PSCustomObject]@{
            BoundaryIds = @("PB-005", "PB-011", "PB-012")
            EventType = "done"
            RequiredPayload = @("type")
            ConsumerOutcome = "not-qualified-compatible"
        }
        "PROTOCOL-SSE-TOOL-CALL-GAP" = [PSCustomObject]@{
            BoundaryIds = @("PB-005", "PB-012", "PB-013")
            EventType = "tool_call"
            ConsumerOutcome = "tool-call-shape-mismatch"
        }
        "PROTOCOL-SSE-ERROR-GAP" = [PSCustomObject]@{
            BoundaryIds = @("PB-005", "PB-011", "PB-012")
            EventType = "error"
            ConsumerOutcome = "error-not-surfaced"
        }
    }
    foreach ($contractId in $expectedSseContracts.Keys) {
        $matches = @($protocols | Where-Object { [string]$_.id -ceq $contractId })
        if ($matches.Count -ne 1) {
            Add-Failure $Failures "P0A1-SSE-TRUTH"
            continue
        }
        $contract = $matches[0]
        $expectedContract = $expectedSseContracts[$contractId]
        $producer = Get-PropertyValue $contract "producer"
        $transport = Get-PropertyValue $contract "transport"
        $consumer = Get-PropertyValue $contract "consumer"
        $compatible = Get-PropertyValue $contract "compatibility"
        $expectedFailure = [string](Get-PropertyValue $contract "expectedFailure")
        $expectedContractProperties = @(
            "id", "boundaryIds", "producer", "transport", "consumer", "compatibility",
            "consumerOutcome", "qualification", "laterRepair", "expectedFailure"
        )
        if ($contractId -cin @("PROTOCOL-SSE-TOOL-CALL-GAP", "PROTOCOL-SSE-ERROR-GAP")) {
            $expectedContractProperties += "staticMismatch"
        }
        if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $contract) $expectedContractProperties) -or
            $null -ne (Get-PropertyValue $contract "wire") -or
            $null -ne (Get-PropertyValue $contract "yielded") -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $contract "boundaryIds") $expectedContract.BoundaryIds) -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $producer) @(
                    "source", "formatterSource", "inputFraming", "input"
                )) -or
            [string](Get-PropertyValue $producer "source") -cne
                "python-backend/aemeath_agent/api/routes_agent.py" -or
            [string](Get-PropertyValue $producer "formatterSource") -cne
                "python-backend/aemeath_agent/api/sse.py" -or
            [string](Get-PropertyValue $producer "inputFraming") -cne "already-framed-sse-text" -or
            [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $producer "input")) -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $transport) @(
                    "source", "dependencySource", "dependencyConstraint", "versionPinned",
                    "exactWireFrozen"
                )) -or
            [string](Get-PropertyValue $transport "source") -cne
                "python-backend/aemeath_agent/api/routes_agent.py" -or
            [string](Get-PropertyValue $transport "dependencySource") -cne
                "python-backend/pyproject.toml" -or
            [string](Get-PropertyValue $transport "dependencyConstraint") -cne
                "sse-starlette>=2.0.0" -or
            (Get-PropertyValue $transport "versionPinned") -isnot [bool] -or
            (Get-PropertyValue $transport "versionPinned") -ne $false -or
            (Get-PropertyValue $transport "exactWireFrozen") -isnot [bool] -or
            (Get-PropertyValue $transport "exactWireFrozen") -ne $false -or
            [string](Get-PropertyValue $consumer "source") -cne
                "src/AemeathDesktopPet/Services/BackendAgentService.cs" -or
            $compatible -isnot [bool] -or $compatible -ne $false -or
            [string](Get-PropertyValue $contract "consumerOutcome") -cne $expectedContract.ConsumerOutcome -or
            [string](Get-PropertyValue $contract "qualification") -cne "P0B.1d" -or
            [string](Get-PropertyValue $contract "laterRepair") -cne "P2.1" -or
            [string]::IsNullOrWhiteSpace($expectedFailure)) {
            Add-Failure $Failures "P0A1-SSE-TRUTH"
        }
        if ($contractId -cin @("PROTOCOL-SSE-TOKEN", "PROTOCOL-SSE-DONE") -and
            (-not (Test-ExactOrdinalSet @(Get-PropertyNames $consumer) @(
                        "source", "eventType", "requiredPayload"
                    )) -or
                [string](Get-PropertyValue $consumer "eventType") -cne $expectedContract.EventType -or
                -not (Test-ExactOrdinalSet @(Get-ArrayProperty $consumer "requiredPayload") `
                    $expectedContract.RequiredPayload))) {
            Add-Failure $Failures "P0A1-SSE-TRUTH"
        } elseif ($contractId -ceq "PROTOCOL-SSE-TOOL-CALL-GAP") {
            $mismatch = Get-PropertyValue $contract "staticMismatch"
            if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $consumer) @(
                        "source", "eventType", "requiredToolNamePath"
                    )) -or
                [string](Get-PropertyValue $consumer "eventType") -cne "tool_call" -or
                [string](Get-PropertyValue $consumer "requiredToolNamePath") -cne "data.name" -or
                -not (Test-ExactOrdinalSet @(Get-PropertyNames $mismatch) @(
                        "kind", "producerToolNamePath", "producerArgumentsPath",
                        "consumerToolNamePath", "consumerHandlesArguments", "argumentsConsumed"
                    )) -or
                [string](Get-PropertyValue $mismatch "kind") -cne "tool-call-shape" -or
                [string](Get-PropertyValue $mismatch "producerToolNamePath") -cne "content" -or
                [string](Get-PropertyValue $mismatch "producerArgumentsPath") -cne "data.args" -or
                [string](Get-PropertyValue $mismatch "consumerToolNamePath") -cne "data.name" -or
                (Get-PropertyValue $mismatch "consumerHandlesArguments") -isnot [bool] -or
                (Get-PropertyValue $mismatch "consumerHandlesArguments") -ne $false -or
                (Get-PropertyValue $mismatch "argumentsConsumed") -isnot [bool] -or
                (Get-PropertyValue $mismatch "argumentsConsumed") -ne $false) {
                Add-Failure $Failures "P0A1-SSE-TRUTH"
            }
        } elseif ($contractId -ceq "PROTOCOL-SSE-ERROR-GAP") {
            $mismatch = Get-PropertyValue $contract "staticMismatch"
            if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $consumer) @(
                        "source", "eventType", "handlesEventType"
                    )) -or
                [string](Get-PropertyValue $consumer "eventType") -cne "error" -or
                (Get-PropertyValue $consumer "handlesEventType") -isnot [bool] -or
                (Get-PropertyValue $consumer "handlesEventType") -ne $false -or
                -not (Test-ExactOrdinalSet @(Get-PropertyNames $mismatch) @(
                        "kind", "producerEventType", "consumerHandlesEventType"
                    )) -or
                [string](Get-PropertyValue $mismatch "kind") -cne "error-visibility" -or
                [string](Get-PropertyValue $mismatch "producerEventType") -cne "error" -or
                (Get-PropertyValue $mismatch "consumerHandlesEventType") -isnot [bool] -or
                (Get-PropertyValue $mismatch "consumerHandlesEventType") -ne $false) {
                Add-Failure $Failures "P0A1-SSE-TRUTH"
            }
        }
    }
}

function Test-QualificationLanes {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $lanes = @(Get-ArrayProperty $Specification "qualificationLanes")
    if (-not (Test-ExactOrdinalSet @(Get-ObjectIds $lanes) $expectedLaneIds) -or $lanes.Count -ne 14) {
        Add-Failure $Failures "P0A1-LANE-COVERAGE"
        return
    }
    foreach ($lane in $lanes) {
        $laneId = [string]$lane.id
        $catalogRows = @($script:liveContext.Traceability.testCatalog | Where-Object {
            [string]$_.lane -ceq $laneId -and
            ([string]$_.ownerStep -clike "P0A.*" -or
                [string]$_.id -ceq "P0B.3e-V-ACCESS-ACCESSIBILITY-JOURNEY")
        })
        $expectedOwners = @(Get-UniqueOrdinalValues @($catalogRows | ForEach-Object { $_.ownerStep }))
        $expectedTests = @($catalogRows | ForEach-Object { [string]$_.id })
        $expectedBehaviors = @(Get-ExpectedLaneBehaviors $laneId)
        if (-not (Test-HasProperties $lane @("id", "required", "rationale", "boundaryIds", "ownerSteps", "testIds")) -or
            (Get-PropertyValue $lane "required") -isnot [bool] -or
            (Get-PropertyValue $lane "required") -ne $true -or
            [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $lane "rationale")) -or
            $catalogRows.Count -eq 0 -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $lane "boundaryIds") $expectedBehaviors) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $lane "ownerSteps") $expectedOwners) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $lane "testIds") $expectedTests)) {
            Add-Failure $Failures "P0A1-LANE-DECISION"
        }
    }
}

function Test-EnvironmentsAndGaps {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $environments = @(Get-ArrayProperty $Specification "supportedEnvironments")
    if (-not (Test-ExactOrdinalSet @(Get-ObjectIds $environments) @($expectedEnvironments.Keys)) -or
        $environments.Count -ne 5) {
        Add-Failure $Failures "P0A1-ENVIRONMENT-COVERAGE"
    }
    foreach ($environment in $environments) {
        $environmentId = [string](Get-PropertyValue $environment "id")
        $expectedEnvironment = $expectedEnvironments[$environmentId]
        if ($null -eq $expectedEnvironment -or
            -not (Test-ExactOrdinalSet @(Get-PropertyNames $environment) @(
                    "id", "os", "status", "capabilityIds", "targetSteps"
                )) -or
            [string](Get-PropertyValue $environment "os") -cne $expectedEnvironment.Os -or
            [string](Get-PropertyValue $environment "status") -cne $expectedEnvironment.Status -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $environment "capabilityIds") $expectedEnvironment.CapabilityIds) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $environment "targetSteps") $expectedEnvironment.TargetSteps)) {
            Add-Failure $Failures "P0A1-ENVIRONMENT-SHAPE"
        }
    }

    $gaps = @(Get-ArrayProperty $Specification "knownGaps")
    $gapIds = @(Get-ObjectIds $gaps)
    if (-not (Test-ExactOrdinalSet @($expectedGapContracts.Keys) $expectedGapIds) -or
        -not (Test-ExactOrdinalSet $gapIds $expectedGapIds) -or $gaps.Count -ne 35) {
        Add-Failure $Failures "P0A1-GAP-COVERAGE"
    }
    $uniqueGapIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($gap in $gaps) {
        $gapId = [string]$gap.id
        $countsAsPassing = Get-PropertyValue $gap "countsAsPassingBaseline"
        $requirementIds = @(Get-ArrayProperty $gap "requirementIds" | ForEach-Object { [string]$_ })
        $traceRequirementIds = @($script:liveContext.Traceability.entries | ForEach-Object { [string]$_.id })
        if ([string]::IsNullOrWhiteSpace($gapId) -or -not $uniqueGapIds.Add($gapId) -or
            -not (Test-HasProperties $gap @(
                    "id", "requirementIds", "boundaryIds", "statement", "laterRedStep",
                    "countsAsPassingBaseline"
                )) -or
            [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $gap "statement")) -or
            [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $gap "laterRedStep")) -or
            $countsAsPassing -isnot [bool] -or
            $countsAsPassing -eq $true -or
            $requirementIds.Count -eq 0 -or
            -not (Test-IsSubset $requirementIds $traceRequirementIds) -or
            @(Get-ArrayProperty $gap "boundaryIds").Count -eq 0 -or
            -not (Test-IsSubset @(Get-ArrayProperty $gap "boundaryIds") $expectedBoundaryIds)) {
            Add-Failure $Failures "P0A1-GAP-CONTRACT"
        }
        $expectedGap = if ($expectedGapContracts.Contains($gapId)) {
            $expectedGapContracts[$gapId]
        } else {
            $null
        }
        if ($null -eq $expectedGap -or
            -not (Test-ExactOrdinalSet $requirementIds $expectedGap.RequirementIds) -or
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $gap "boundaryIds") $expectedGap.BoundaryIds) -or
            [string](Get-PropertyValue $gap "laterRedStep") -cne $expectedGap.LaterRedStep -or
            $countsAsPassing -isnot [bool] -or $countsAsPassing -ne $false) {
            Add-Failure $Failures "P0A1-GAP-CONTRACT"
        }
        if ($null -ne $expectedGap -and $null -ne (Get-PropertyValue $expectedGap "Statement") -and
            [string](Get-PropertyValue $gap "statement") -cne
                [string](Get-PropertyValue $expectedGap "Statement")) {
            Add-Failure $Failures "P0A1-GAP-CONTRACT"
        }
        if ($null -ne $expectedGap -and $null -ne (Get-PropertyValue $expectedGap "SourceLocators") -and
            -not (Test-ExactOrdinalSet @(Get-ArrayProperty $gap "sourceLocators") `
                @(Get-PropertyValue $expectedGap "SourceLocators"))) {
            Add-Failure $Failures "P0A1-GAP-CONTRACT"
        }
    }
    $coveredRequirements = @(Get-UniqueOrdinalValues @($gaps | ForEach-Object {
                Get-ArrayProperty $_ "requirementIds"
            }))
    $requiredGapCoverage = @($script:liveContext.Traceability.entries | Where-Object {
            [string]$_.namespace -ceq "CURRENT" -and
            [string]$_.id -cnotlike "CURRENT:AC-*" -and
            [string]$_.currentStatus -cin @("Partial", "Planned")
        } | ForEach-Object { [string]$_.id })
    foreach ($requirementId in $requiredGapCoverage) {
        if ($coveredRequirements -cnotcontains $requirementId) {
            Add-Failure $Failures "P0A1-GAP-COVERAGE"
        }
    }
    foreach ($boundary in @(Get-ArrayProperty $Specification "boundaries")) {
        $boundaryId = [string]$boundary.id
        foreach ($gapId in @(Get-ArrayProperty $boundary "knownGapIds")) {
            $gap = @($gaps | Where-Object { $_.id -ceq $gapId })
            if ($gap.Count -ne 1 -or @($gap[0].boundaryIds) -cnotcontains $boundaryId) {
                Add-Failure $Failures "P0A1-GAP-LINK"
            }
        }
    }
    foreach ($gap in $gaps) {
        foreach ($boundaryId in @(Get-ArrayProperty $gap "boundaryIds")) {
            $boundary = @((Get-ArrayProperty $Specification "boundaries") | Where-Object { $_.id -ceq $boundaryId })
            if ($boundary.Count -ne 1 -or @($boundary[0].knownGapIds) -cnotcontains [string]$gap.id) {
                Add-Failure $Failures "P0A1-GAP-LINK"
            }
        }
    }
}

function Test-ClaimAndEnvironmentPolicies {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $expectedClaim = @'
{"productAndPreservationOracles":{"classification":"product-or-preservation-oracle","verification":"clean-room-exact-allowlist-review","reviewerId":"clean-room-preservation-reviewer-06"},"governanceHistory":[{"subjects":["previous-specification","previous-traceability"],"classification":"governance-history-not-product-oracle","owner":"P0A.1-V-STATIC-STATIC-CONTRACT","fixedAuthorityVerificationRequired":true,"independentProductOracleAllowed":false},{"subjects":["DATA-V1-through-V4-lineage","DATA-V1-raw-byte-copy"],"classification":"governance-history-not-product-oracle","owner":"P0A.1-V-STATIC-STATIC-CONTRACT","fixedAuthorityVerificationRequired":true,"independentProductOracleAllowed":false},{"subjects":["Git-revisions"],"classification":"governance-history-not-product-oracle","owner":"P0A.1-V-STATIC-STATIC-CONTRACT","fixedAuthorityVerificationRequired":true,"independentProductOracleAllowed":false},{"subjects":["historical-RED-metadata","historical-review-metadata"],"classification":"governance-history-not-product-oracle","owner":"P0A.1-V-STATIC-STATIC-CONTRACT","fixedAuthorityVerificationRequired":true,"independentProductOracleAllowed":false}],"portableValidation":{"command":"./tools/verification/Test-PreservationSpecification.ps1","engines":["Windows PowerShell 5.1","pwsh 7.4+"],"implementationSources":["tools/verification/Test-PreservationSpecification.ps1","tools/ci/CiDeliveryContract.psm1"],"capabilitySources":["docs/verification/manifests/D0.4-v3.yml","docs/verification/environments/D0.4-readiness-v1.json"],"allowedChecksBeforeGreen":["parse","static","read-only-capability"],"fullValidatorAllowedBeforeGreen":false,"projectExecutionAllowedBeforeGreen":false,"legacySourceAccessAllowedBeforeGreen":false,"networkAccessAllowedBeforeGreen":false}}
'@
    $expectedSourceIdentity = @'
{"historicalBaseline":{"field":"baseline.commitSha","commitSha":"43f9c288f843f7620ffee5eee3504f52875f4774","classification":"historical-provenance","requiresLiveHeadEquality":false},"liveCheckout":{"source":"git-rev-parse-HEAD","requiredPattern":"^[0-9a-f]{40}$"},"ciCheckout":{"environmentVariable":"SOURCE_SHA","activation":"non-empty","requiredPattern":"^[0-9a-f]{40}$","comparison":"ordinal","mustEqualLiveHead":true},"localCheckout":{"condition":"SOURCE_SHA-empty-or-unset","historicalBaselineEqualityRequired":false},"discoveryMarker":{"field":"sourceSha","valueSource":"live-git-head"},"statement":"baseline.commitSha is historical provenance and does not constrain the current checkout. Live Git HEAD must be lowercase 40-hex. When SOURCE_SHA is non-empty it must also be lowercase 40-hex and ordinal-equal to live HEAD; when SOURCE_SHA is empty or unset, live HEAD may differ from baseline.commitSha. The discovery marker sourceSha is resolved from live HEAD."}
'@
    $expectedEnvironment = @'
{"d0_4CompletionMeaning":"D0.4 completion means environment owners, readiness states, and blockers are evidenced.","interactiveWorkerProvisioningImplied":false,"blockedPrerequisitePolicy":{"planReference":"docs/plans/20260722-jarvis-assistant-tdd-checklist.md line 373","rule":"A blocked prerequisite blocks the first plan step that requires it."},"supportedEnvironmentValues":"The five supportedEnvironments records remain normative and unchanged from preservation-spec-v2."}
'@
    $claim = Get-PropertyValue $Specification "claimVerificationPolicy"
    $sourceIdentity = Get-PropertyValue $Specification "sourceIdentityPolicy"
    $environment = Get-PropertyValue $Specification "environmentReadinessInterpretation"
    if (($claim | ConvertTo-Json -Depth 20 -Compress) -cne $expectedClaim.Trim()) {
        Add-Failure $Failures "P0A1-CLAIM-VERIFICATION-POLICY"
    }
    if (($environment | ConvertTo-Json -Depth 20 -Compress) -cne $expectedEnvironment.Trim()) {
        Add-Failure $Failures "P0A1-ENVIRONMENT-READINESS-INTERPRETATION"
    }
    if (($sourceIdentity | ConvertTo-Json -Depth 20 -Compress) -cne
        $expectedSourceIdentity.Trim()) {
        Add-Failure $Failures "P0A1-SOURCE-IDENTITY-POLICY"
    }
}

function Get-AllSourceLocators {
    param([object]$InputObject)

    if ($null -eq $InputObject -or $InputObject -is [string]) { return @() }
    $result = [Collections.Generic.List[string]]::new()
    if ($InputObject -is [Collections.IEnumerable] -and
        $InputObject -isnot [Management.Automation.PSCustomObject]) {
        foreach ($item in $InputObject) {
            foreach ($locator in @(Get-AllSourceLocators $item)) { $result.Add($locator) }
        }
        return $result.ToArray()
    }
    foreach ($property in $InputObject.PSObject.Properties) {
        if ($property.Name -ceq "sourceLocators") {
            foreach ($locator in @($property.Value)) { $result.Add([string]$locator) }
        }
        foreach ($locator in @(Get-AllSourceLocators $property.Value)) { $result.Add($locator) }
    }
    return $result.ToArray()
}

function Test-ComponentLocatorClosure {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $predecessorLocators = @(Get-UniqueOrdinalValues @(
            Get-AllSourceLocators $script:liveContext.PredecessorSpecification
        ))
    $expectedCurrentLocators = @($predecessorLocators | ForEach-Object {
            if ([string]$_ -ceq ".github/workflows") {
                ".github/workflows/release.yml"
            } else {
                [string]$_
            }
        })
    $currentUnique = @(Get-UniqueOrdinalValues @(Get-AllSourceLocators $Specification))
    if ($predecessorLocators.Count -ne 92 -or $currentUnique.Count -ne 92 -or
        -not (Test-ExactOrdinalSet @(Get-UniqueOrdinalValues $expectedCurrentLocators) $currentUnique)) {
        Add-Failure $Failures "P0A1-LOCATOR-CLOSURE"
    }
    foreach ($locator in $currentUnique) {
        $path = ([string]$locator).Split('#')[0]
        $covered = @($expectedReviewerSources | Where-Object {
                $path -ceq [string]$_ -or
                $path.StartsWith(([string]$_).TrimEnd('/') + '/', [StringComparison]::Ordinal)
            }).Count -gt 0
        if (-not $covered) { Add-Failure $Failures "P0A1-LOCATOR-CLOSURE" }
    }
    $components = @(Get-ArrayProperty (Get-PropertyValue $Specification "inventories") "components")
    $build = @($components | Where-Object { [string](Get-PropertyValue $_ "id") -ceq "CMP-BUILD-PACKAGE" })
    if ($build.Count -ne 1 -or
        -not (Test-ExactOrdinalSet @(Get-ArrayProperty $build[0] "sourceLocators") @(
                "src/AemeathDesktopPet/AemeathDesktopPet.csproj",
                "python-backend/pyproject.toml",
                ".github/workflows/release.yml"
            ))) {
        Add-Failure $Failures "P0A1-LOCATOR-CLOSURE"
    }
}

function Test-Provenance {
    param(
        [object]$Specification,
        [Collections.Generic.List[string]]$Failures
    )

    $provenance = Get-PropertyValue $Specification "provenance"
    if (-not (Test-HasProperties $provenance @("authorDeclarations", "reviewerAssignments"))) {
        Add-Failure $Failures "P0A1-PROVENANCE-SHAPE"
        Add-Failure $Failures "P0A1-CLEAN-REVIEWER"
        return
    }
    $authors = @(Get-ArrayProperty $provenance "authorDeclarations")
    $reviewers = @(Get-ArrayProperty $provenance "reviewerAssignments")
    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $provenance) @(
                "authorDeclarations", "reviewerAssignments"
            )) -or
        $authors.Count -ne 1 -or $reviewers.Count -ne 1) {
        Add-Failure $Failures "P0A1-PROVENANCE-COVERAGE"
        Add-Failure $Failures "P0A1-CLEAN-REVIEWER"
    }

    foreach ($pathRecord in @((Get-ArrayProperty $Specification "sources") + (Get-ArrayProperty $Specification "artifacts"))) {
        $path = [string](Get-PropertyValue $pathRecord "path")
        foreach ($legacyRoot in $expectedLegacyRoots) {
            if (-not [string]::IsNullOrWhiteSpace($legacyRoot) -and
                $path.StartsWith($legacyRoot.TrimEnd('/') + "/", [StringComparison]::Ordinal)) {
                Add-Failure $Failures "P0A1-LEGACY-ISOLATION"
            }
        }
    }

    $exposedAuthorFound = $false
    foreach ($author in $authors) {
        if ((Test-ExactOrdinalSet @(Get-PropertyNames $author) @(
                    "id", "legacyExposure", "mayApproveIndependentOracles", "statement"
                )) -and
            [string](Get-PropertyValue $author "id") -ceq "P0A1-AUTHOR-01" -and
            [string](Get-PropertyValue $author "legacyExposure") -ceq "exposed" -and
            (Get-PropertyValue $author "mayApproveIndependentOracles") -is [bool] -and
            (Get-PropertyValue $author "mayApproveIndependentOracles") -eq $false -and
            -not [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $author "statement"))) {
            $exposedAuthorFound = $true
        }
    }
    if (-not $exposedAuthorFound) { Add-Failure $Failures "P0A1-EXPOSURE-DECLARATION" }

    $cleanReviewerFound = $false
    foreach ($reviewer in $reviewers) {
        $exposure = [string](Get-PropertyValue $reviewer "legacyExposure")
        $artifactIds = @(Get-ArrayProperty $reviewer "artifactIds")
        $defaultDeny = Get-PropertyValue $reviewer "defaultDenyUnlistedSources"
        if ((Test-ExactOrdinalSet @(Get-PropertyNames $reviewer) @(
                    "id", "role", "legacyExposure", "status", "evidencePath", "evidenceAccess",
                    "defaultDenyUnlistedSources", "allowedSources", "forbiddenSourceRoots",
                    "allowedReviewActions", "forbiddenReviewActions", "forbiddenCategories",
                    "artifactIds", "boundaryIds"
                )) -and
            [string](Get-PropertyValue $reviewer "id") -ceq "clean-room-preservation-reviewer-06" -and
            [string](Get-PropertyValue $reviewer "role") -ceq "unexposed preservation specification reviewer" -and
            $exposure -ceq "unexposed" -and
            [string](Get-PropertyValue $reviewer "status") -ceq "assigned-after-v9-before-review" -and
            [string](Get-PropertyValue $reviewer "evidencePath") -ceq
                "docs/verification/evidence/P0A.1-clean-room-review-v7.md" -and
            [string](Get-PropertyValue $reviewer "evidenceAccess") -ceq "write-only-output" -and
            $defaultDeny -is [bool] -and $defaultDeny -eq $true -and
            (Test-ExactOrdinalSet @($artifactIds | ForEach-Object { [string]$_ }) @($expectedFixtureArtifacts.Keys)) -and
            (Test-ExactOrdinalSet @(Get-ArrayProperty $reviewer "boundaryIds") $expectedBoundaryIds) -and
            (Test-ExactOrdinalSet @(Get-ArrayProperty $reviewer "allowedSources") $expectedReviewerSources) -and
            (Test-ExactOrdinalSet @(Get-ArrayProperty $reviewer "allowedReviewActions") @(
                    "static-parse", "read-only-capability-check"
                )) -and
            (Test-ExactOrdinalSet @(Get-ArrayProperty $reviewer "forbiddenReviewActions") @(
                    "full-validator-execution", "project-execution", "legacy-source-access",
                    "network-access"
                )) -and
            (Test-ExactOrdinalSet @(Get-ArrayProperty $reviewer "forbiddenSourceRoots") $expectedLegacyRoots) -and
            (Test-ExactOrdinalSet @(Get-ArrayProperty $reviewer "forbiddenCategories") $expectedForbiddenCategories)) {
            $cleanReviewerFound = $true
        }
    }
    if (-not $cleanReviewerFound) { Add-Failure $Failures "P0A1-CLEAN-REVIEWER" }
}

function Test-CleanReviewEvidenceLabels {
    param([string[]]$EvidenceLines)

    $labelContracts = [ordered]@{
        "Reviewer assignment" = "- Reviewer assignment: ``clean-room-preservation-reviewer-06``"
        "Legacy exposure" = "- Legacy exposure: ``unexposed``"
        "Verdict" = "- Verdict: **PASS**"
        "Finding census" = "- Finding census: **C=0, I=0, M=0**"
    }
    foreach ($label in $labelContracts.Keys) {
        $prefix = "- ${label}:"
        $labelLines = @($EvidenceLines | Where-Object {
                ([string]$_).StartsWith($prefix, [StringComparison]::Ordinal)
            })
        if ($labelLines.Count -ne 1 -or
            [string]$labelLines[0] -cne [string]$labelContracts[$label]) {
            return $false
        }
    }
    return $true
}

function Test-CleanReviewEvidence {
    param([Collections.Generic.List[string]]$Failures)

    $fullPath = Resolve-RepositoryPath $cleanReviewEvidencePath
    if ($null -eq $fullPath -or -not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
        return
    }
    $evidence = Get-StrictUtf8Text $fullPath
    if ($null -eq $evidence) {
        Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
        return
    }
    $evidenceLines = @($evidence.Replace("`r`n", "`n").Replace("`r", "`n").Split("`n"))
    if (-not (Test-CleanReviewEvidenceLabels $evidenceLines)) {
        Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
        return
    }

    $requiredBindings = [ordered]@{}
    $fileBindings = @(
        @($specificationRelativePath, "preservation-specification", 1),
        @("docs/verification/manifests/P0A.1-v9.yml", "risk-lane-manifest", 1),
        @("docs/verification/traceability-v2.yml", "traceability", 352),
        @("tests/fixtures/preservation/v1/data-v5.json", "data-fixture", 17),
        @("tests/fixtures/preservation/v1/oracles-v1.json", "oracle-fixture", 28),
        @("tests/fixtures/preservation/v1/protocol-v3.json", "protocol-fixture", 15),
        @("tests/fixtures/preservation/v1/resources-v1.json", "resource-fixture", 11),
        @("python-backend/pyproject.toml", "source-file", 1),
        @(".github/workflows/release.yml", "source-file", 1),
        @("tools/verification/Test-PreservationSpecification.ps1", "validator", 1),
        @("tools/ci/CiDeliveryContract.psm1", "validator-module", 1),
        @("docs/verification/manifests/D0.4-v3.yml", "capability-manifest", 1),
        @("docs/verification/environments/D0.4-readiness-v1.json", "capability-readiness", 1)
    )
    foreach ($definition in $fileBindings) {
        $path = [string]$definition[0]
        $bindingPath = Resolve-RepositoryPath $path
        if ($null -eq $bindingPath -or -not (Test-Path -LiteralPath $bindingPath -PathType Leaf)) {
            Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
            return
        }
        $requiredBindings[$path] = [PSCustomObject]@{
            Kind = [string]$definition[1]
            Bytes = [long](Get-Item -LiteralPath $bindingPath).Length
            Count = [long]$definition[2]
            Digest = Get-RawFileSha256 $bindingPath
        }
    }
    foreach ($rootPath in $expectedProductionRoots.Keys) {
        $root = $script:liveContext.ProductionRoots[$rootPath]
        $requiredBindings[$rootPath] = [PSCustomObject]@{
            Kind = "production-root"
            Bytes = [long](Get-PropertyValue $root "ByteCount")
            Count = [long](Get-PropertyValue $root "FileCount")
            Digest = [string](Get-PropertyValue $root "Sha256")
        }
    }
    if ($requiredBindings.Count -ne 15) {
        Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
        return
    }

    $bindingLines = @($evidenceLines | Where-Object { $_ -clike "- BINDING *" })
    $seenPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    if ($bindingLines.Count -ne 15) {
        Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
        return
    }
    foreach ($line in $bindingLines) {
        if ($line -cnotmatch '^- BINDING path=(?<path>\S+) kind=(?<kind>[a-z-]+) hash=SHA-256 bytes=(?<bytes>\d+) count=(?<count>\d+) digest=(?<digest>[0-9a-f]{64})$') {
            Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
            continue
        }
        $path = [string]$Matches.path
        $expected = if ($requiredBindings.Contains($path)) { $requiredBindings[$path] } else { $null }
        if (-not $seenPaths.Add($path) -or $null -eq $expected -or
            [string]$Matches.kind -cne [string](Get-PropertyValue $expected "Kind") -or
            [long]$Matches.bytes -ne [long](Get-PropertyValue $expected "Bytes") -or
            [long]$Matches.count -ne [long](Get-PropertyValue $expected "Count") -or
            [string]$Matches.digest -cne [string](Get-PropertyValue $expected "Digest")) {
            Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
        }
    }
    if (-not (Test-ExactOrdinalSet @($seenPaths) @($requiredBindings.Keys))) {
        Add-Failure $Failures "P0A1-CLEAN-REVIEW-EVIDENCE"
    }
}

function Get-SpecificationFailures {
    param([object]$Specification)

    $failures = [Collections.Generic.List[string]]::new()
    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $Specification) $expectedTopLevelProperties)) {
        Add-Failure $failures "P0A1-SPEC-SHAPE"
    }
    if ([long](Get-PropertyValue $Specification "schemaVersion") -ne 1 -or
        [string](Get-PropertyValue $Specification "documentType") -cne "preservation-specification" -or
        [string](Get-PropertyValue $Specification "specId") -cne "P0A.1-preservation-spec-v5" -or
        [long](Get-PropertyValue $Specification "revision") -ne 5 -or
        [string](Get-PropertyValue $Specification "status") -cne "frozen") {
        Add-Failure $failures "P0A1-SPEC-IDENTITY"
    }

    $previousSpecification = Get-PropertyValue $Specification "previousSpecification"
    if (-not (Test-ExactOrdinalSet @(Get-PropertyNames $previousSpecification) @(
                "path", "id", "revision", "sha256", "status"
            )) -or
        [string](Get-PropertyValue $previousSpecification "path") -cne
            "docs/verification/preservation-spec-v4.yml" -or
        [string](Get-PropertyValue $previousSpecification "id") -cne "P0A.1-preservation-spec-v4" -or
        [long](Get-PropertyValue $previousSpecification "revision") -ne 4 -or
        [string](Get-PropertyValue $previousSpecification "sha256") -cne
            $frozenPredecessorSpecificationSha256 -or
        [string](Get-PropertyValue $previousSpecification "status") -cne "BLOCK" -or
        (Get-RawFileSha256 $predecessorSpecificationPath) -cne $frozenPredecessorSpecificationSha256) {
        Add-Failure $failures "P0A1-SPEC-PREDECESSOR"
    }

    $governingManifest = Get-PropertyValue $Specification "governingManifest"
    if (-not (Test-HasProperties $governingManifest @("path", "id", "sha256")) -or
        [string](Get-PropertyValue $governingManifest "path") -cne
            "docs/verification/manifests/P0A.1-v9.yml" -or
        [string](Get-PropertyValue $governingManifest "id") -cne "P0A.1-v9" -or
        [string](Get-PropertyValue $governingManifest "sha256") -cne $frozenManifestSha256 -or
        $script:liveContext.ManifestSha256 -cne $frozenManifestSha256 -or
        [string](Get-PropertyValue $script:liveContext.Manifest "manifestId") -cne "P0A.1-v9" -or
        [string](Get-PropertyValue $script:liveContext.Manifest "baselineSha") -cne $frozenBaselineSha) {
        Add-Failure $failures "P0A1-MANIFEST-BINDING"
    }

    Test-ManifestContract $failures
    Test-Inventory (Get-PropertyValue $Specification "inventories") $failures
    Test-DataFixtureContract $failures
    Test-PersistedDataContract $Specification $failures
    Test-TraceabilityBinding $Specification $failures
    Test-TraceOwnerContracts $failures
    Test-SourceBindings $Specification $failures
    Test-ProductionBaseline $Specification $failures
    Test-ArtifactBindings $Specification $failures
    Test-SemanticFixtures $failures
    Test-QualificationLanes $Specification $failures
    Test-EnvironmentsAndGaps $Specification $failures
    Test-ClaimAndEnvironmentPolicies $Specification $failures
    Test-ComponentLocatorClosure $Specification $failures
    Test-Provenance $Specification $failures
    Test-CleanReviewEvidence $failures
    Test-Boundaries $Specification $failures
    Test-BoundaryDataLinks $Specification $failures
    return $failures.ToArray()
}

function Write-ProbePass {
    param([string]$Message)

    $script:probeCount++
    Write-Host "PASS $Message"
}

function Assert-MutationRejected {
    param(
        [string]$Name,
        [object]$Mutation,
        [string]$ExpectedFailure
    )

    $failures = @(Get-SpecificationFailures $Mutation)
    if ($failures -cnotcontains $ExpectedFailure) {
        throw "[$ExpectedFailure] Mutation '$Name' was not rejected by its named diagnostic; actual=[$($failures -join ', ')]."
    }
    Write-ProbePass "$Name mutation rejected with [$ExpectedFailure]"
}

$authorityContext = Get-AuthorityObservationContext
Assert-FixedInputAuthority $authorityContext
Assert-FixedInputAuthorityMutationGuards $authorityContext
Assert-SourceIdentityMutationGuards
Assert-FixedInputAuthority $authorityContext
$script:liveContext = Get-LiveContext $authorityContext
Import-Module $ciDeliveryContractModule -Force
$specification = Get-StrictJsonValue $specificationPath "P0A1-SPEC-INPUT"

$baselineFailures = @(Get-SpecificationFailures $specification)
if ($baselineFailures.Count -ne 0) {
    throw "[P0A1-SPEC-INVALID] Frozen preservation specification failed: $($baselineFailures -join ', ')."
}
Write-ProbePass "complete frozen preservation specification"

$missingBoundary = Copy-JsonValue $specification
$missingBoundary.boundaries = @($missingBoundary.boundaries | Where-Object { $_.id -cne "PB-018" })
Assert-MutationRejected "missing PB" $missingBoundary "P0A1-PB-COVERAGE"

$missingRequirementMap = Copy-JsonValue $specification
$missingRequirementMap.traceability.requirementIds = @(
    $missingRequirementMap.traceability.requirementIds | Where-Object { $_ -cne "PRD:RISK-010" }
)
Assert-MutationRejected "missing requirement-map entry" $missingRequirementMap "P0A1-REQUIREMENT-COVERAGE"

$missingLane = Copy-JsonValue $specification
$missingLane.qualificationLanes = @($missingLane.qualificationLanes | Where-Object { $_.id -cne "V-LEGACY" })
Assert-MutationRejected "missing lane" $missingLane "P0A1-LANE-COVERAGE"

$fixtureHashDrift = Copy-JsonValue $specification
$fixtureHashDrift.artifacts[0].sha256 = "0000000000000000000000000000000000000000000000000000000000000000"
Assert-MutationRejected "fixture hash drift" $fixtureHashDrift "P0A1-FIXTURE-HASH"

$sseTokenContracts = @(
    (Get-ArrayProperty $script:liveContext.Fixtures["P0A1-PROTOCOL-V3"] "contracts") |
        Where-Object { [string]$_.id -ceq "PROTOCOL-SSE-TOKEN" }
)
if ($sseTokenContracts.Count -ne 1) {
    throw "[P0A1-SSE-TRUTH] Cannot run the SSE compatibility mutation without one token contract."
}
$originalSseCompatibility = $sseTokenContracts[0].compatibility
try {
    $sseTokenContracts[0].compatibility = $true
    Assert-MutationRejected "SSE compatibility lie" $specification "P0A1-SSE-TRUTH"
} finally {
    $sseTokenContracts[0].compatibility = $originalSseCompatibility
}

$predecessorHashDrift = Copy-JsonValue $specification
$predecessorHashDrift.previousSpecification.sha256 =
    "0000000000000000000000000000000000000000000000000000000000000000"
Assert-MutationRejected "specification predecessor hash drift" `
    $predecessorHashDrift `
    "P0A1-SPEC-PREDECESSOR"

$dataRecords = @(Get-ArrayProperty $script:liveContext.Fixtures["P0A1-DATA-V5"] "records")
$configDataRecords = @($dataRecords | Where-Object {
        [string](Get-PropertyValue $_ "id") -ceq "DATA-CONFIG-DEFAULTS"
    })
if ($configDataRecords.Count -ne 1) {
    throw "[P0A1-DATA-FIXTURE-CONTRACT] Cannot run the durable-target mutation without DATA-CONFIG-DEFAULTS."
}
$originalReachabilityStatus = $configDataRecords[0].reachability.read.status
try {
    $configDataRecords[0].reachability.read.status = $false
    Assert-MutationRejected "durable-target reachability drift" `
        $specification `
        "P0A1-DATA-FIXTURE-CONTRACT"
} finally {
    $configDataRecords[0].reachability.read.status = $originalReachabilityStatus
}

if ($probeCount -ne 8) {
    throw "[P0A1-DISCOVERY] Expected exactly 8 preservation specification probes, found $probeCount."
}
Write-CiDiscoveryMarker -ResultId "P0A.1-V-STATIC-STATIC-CONTRACT" `
    -ActualDiscovery $probeCount `
    -RepositoryRoot $repositoryRoot
Write-Host "Preservation specification tests passed ($probeCount probes; zero skips)."

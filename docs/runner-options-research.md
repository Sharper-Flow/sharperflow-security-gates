# Self-Hosted Runner + Cost Optimization Research — June 2026

**Date:** 2026-06-17
**Owner:** Sharper-Flow (Azure tenant: `sharperflow.com`, billing type: MCA Individual, PAYG)
**Question:** Can we cut the ~$500/mo GitHub Actions bill, and what's the cheapest reliable path?

## TL;DR (ranked by impact)

1. **Upgrade GitHub Team → Enterprise** — saves **~$266/mo** (15 users × $19.25 annual). Includes 50,000 Actions min/mo. [Source](https://github.com/pricing).
2. **Apply to Microsoft for Startups** — **$5,000 in Azure credits** (10-min app, no investor code needed for bootstrapped path). Covers years of runner compute. [Source](https://www.microsoft.com/en-us/startups).
3. **Self-host runner on Azure Container Apps Jobs (consumption)** — **~$1-3/mo** with scale-to-zero, or $0 if on MfS credits. [Source](https://learn.microsoft.com/en-us/azure/container-apps/jobs).
4. **Disable GHAS Code Security** in org Settings — saves **$30/mo** flat.
5. **Use Visual Studio Subscription Azure credit** if a team member owns a VS Standard sub — **$50-150/mo** credit on a separate VS-Offer Azure sub. [Source](https://learn.microsoft.com/en-us/visualstudio/subscriptions/vs-azure-eligibility).

**Retroactive upgrade: NOT POSSIBLE** — GitHub plan changes bill immediately with proration, no refund of prepaid Team portion. [Source](https://docs.github.com/en/enterprise-cloud@latest/billing/concepts/impact-of-plan-changes).

## Critical pricing context (2026 changes)

- **Jan 1, 2026:** GitHub-hosted Linux 2-core rate dropped from $0.008/min → $0.006/min (up to 39% off hosted).
- **Mar 1, 2026:** Self-hosted runners on **private repos** now charged **$0.002/min** (consumes plan quota). Public-repo self-hosted remains free.
- **Implication:** Pure self-host cost case is weaker. **Hybrid is now the default** (hosted for commodity builds, self-hosted for network/custom needs). [Source](https://github.com/resources/insights/2026-pricing-changes-for-github-actions), [PocketLantern analysis](https://pocketlantern.dev/briefs/github-actions-hosted-vs-self-hosted-runner-pricing-2026).

## Sharper-Flow specific math

### Current state (June 2026, partial month, 17 days)

- 51,986 GitHub Actions Linux min on PokeEdge → $311 gross / $284 net
- 30,000 min on PokeEdge-Web in March (now ~$0/mo — well-tuned)
- GHAS 1 user × $30/mo
- **Burn rate:** ~$500/mo projected for end of June

### Options ranked by net dollar impact

#### Option A: GitHub Enterprise upgrade alone — **saves $266/mo**

| Item | Cost |
|---|---:|
| Team (current) — 15 users × $4 | $60/mo |
| Team — Actions overage (~$500) | $500/mo |
| **Team total** | **$560/mo** |
| Enterprise — 15 users × $19.25 (annual price) | $289/mo |
| Enterprise — 50,000 Actions min included | $0 |
| **Enterprise total** | **$289/mo** |
| **Net savings** | **$271/mo = $3,252/yr** |

**Caveats:**
- Annual contract (pays full $19.25/user even if you cancel mid-year, with proration rules).
- Includes SAML SSO, audit log streaming, 99.9% SLA — useful for compliance even if not currently needed.
- **Confirm 50,000 min/mo covers actual volume.** If consistently over 50k min, the overage is $0.008/min and Enterprise stops paying off.

**Action:** Contact GitHub Sales (https://github.com/enterprise/contact) or self-upgrade in org billing. Quote `19.25/user/mo annual`.

#### Option B: Microsoft for Startups — **$5,000 in Azure credits**

| Item | Detail |
|---|---|
| Bootstrapped path (no investor code) | $1,000 (90 days) + $4,000 (180 days) after business verification = $5,000 total |
| Investor network path (referral code) | up to $150,000 |
| Eligibility | Privately held, software product, pre-Series C, for-profit, not a consultancy/crypto/edu |
| Lifelong cap | $350,000 lifetime free Azure credits |
| Application URL | https://www.microsoft.com/en-us/startups |
| Approval time | ~3 business days |

**Why this is the gold:** $5,000 covers ~28 years of D2s_v5 spot compute, or 10+ months of full Azure bill. The application is 10 minutes, no risk.

**Caveat:** Credits apply to a **new MfS Azure sub**, not the existing SharperFlow RG 1 MCA sub. Networking to existing PokeEdge resources requires VNet peering or public endpoint config.

**Sharper-Flow status check:** SharperFlow is a registered LLC (confirmed by `SharperFlow LLC` MCA account in Azure). Likely eligible. The existing MCA Individual sub doesn't disqualify them.

#### Option C: Self-hosted runner architecture options

| Option | Idle cost | Active cost | Best for |
|---|---|---|---|
| D2s_v5 spot 24/7 | $0.0203/hr (~$15/mo) | $0.0203/hr | Simple, low-effort, always warm |
| D2s_v5 PAYG 24/7 | $0.096/hr (~$70/mo) | $0.096/hr | No eviction risk |
| VMSS spot + auto-shutdown + scale-from-zero | $0 idle | $0.0203/hr only when jobs | Best cost/operational balance |
| **Azure Container Apps Jobs (consumption)** | **$0 idle** | **$0.000024/vCPU-sec** | **Best for CI — scales to zero** |
| AKS spot node pool | $0 idle (if no always-on) | $0.0203/hr | Overkill for 1-2 runners |

**Container Apps Jobs caveat:** A "runner" pattern needs the runner agent installed in the image. `myoung34/github-runner` or `summerwind/actions-runner` Docker images work. Job startup latency 10-30s (cold start), acceptable for CI.

**For Sharper-Flow:** Use Container Apps Jobs for the runner. Self-host on MfS credits (Option B) = $0/mo for years. If MfS unavailable, $1-3/mo on PAYG.

#### Option D: Visual Studio Subscription Azure credit

| VS sub | Monthly credit |
|---|---:|
| Professional Standard (annual) | $50/mo |
| Enterprise Standard (annual) | $150/mo |
| Test Pro Standard | $50/mo |
| VS monthly (cloud) | $0 (not eligible) |

**Key constraints:**
1. Credit requires a **new "Visual Studio" Azure subscription** (separate from existing PAYG sub)
2. **One VS sub per subscriber**
3. **$0 spending limit by default** — auto-pauses at credit exhaustion
4. Monthly reset (doesn't roll over)
5. Applies to any Azure service including VMs

**Sharper-Flow applicability:** Only useful if a team member already owns a VS Standard subscription. If yes, $50/mo credit covers D2s_v5 spot 24/7 with $35/mo headroom.

#### Option E: Azure Hybrid Benefit for Linux

- **Not applicable.** AHB for Linux only applies to RHEL and SLES PAYG marketplace images. Ubuntu (the standard Actions runner OS) is not covered. AHB saves $0 on a self-hosted Ubuntu runner.

#### Option F: Bundle with M365 / MfS

- **M365 E3/E5 + GitHub Enterprise:** Does NOT bundle. M365 E3 is $39/user; GitHub Enterprise is $39/user standalone. Priced independently. Skip.
- **Visual Studio Subscriptions with GitHub Enterprise:** Only available via Enterprise Agreement (EA). Sharper-Flow is on MCA Individual, not EA. Skip unless they commit to EA (which has minimums of 500+ seats or ~$3k/yr Azure commit).

## Recommended action plan

```
Step 1 (parallel, 10 min each):
  [ ] Apply to Microsoft for Startups → $5k Azure credits
  [ ] Upgrade GitHub Team → Enterprise → save $266/mo immediately
  [ ] Disable GHAS Code Security → save $30/mo

Step 2 (after MfS approval, ~3 business days):
  [ ] Provision runner on new MfS Azure sub via Container Apps Jobs
  [ ] Use myoung34/github-runner image, register with sharper-flow org
  [ ] Add `runs-on: [self-hosted, linux, x64, mfs-runner]` to high-cost jobs
  [ ] Keep `ubuntu-latest` for security scans (Trivy, Gitleaks) where isolation matters

Step 3 (monitor 2 weeks):
  [ ] Track spot eviction / job failure rate
  [ ] Compare actual cost to estimate
  [ ] Decide on long-term pattern (more VMs? dedicated PAYG runner?)

Step 4 (if MfS denied or credits exhaust):
  [ ] Check for existing VS Standard subscription holders
  [ ] Activate $50/mo credit, host on new VS-Offer sub
  [ ] Or accept $1-3/mo Container Apps Jobs on existing PAYG sub
```

## Architecture: which jobs to migrate to self-hosted?

| Job | Type | Recommend |
|---|---|---|
| `pr-gate` (unit + api + arch) | Heavy compute, retry-safe | **Self-hosted** |
| `Deploy PokeEdge API to Production` | Heavy, network access to Azure | **Self-hosted** (faster + private) |
| `Staging Deploy` | Heavy, network access to Azure | **Self-hosted** |
| `Promote to Staging` | Light | Hosted (don't bother) |
| `Security / Trivy` | Ephemeral, isolation matters | **Hosted** (keep on GitHub) |
| `Security / Gitleaks`, `OSV`, `Semgrep` | Ephemeral | **Hosted** |
| `Build` (web CI) | Medium | Hosted (small, fast enough) |
| `Test` (web CI) | Medium, deterministic | Hosted |

**Pattern:** Migrate the heavy, long-running, network-bound jobs to self-hosted. Keep short, security-scanning jobs on GitHub-hosted for simplicity and isolation.

## What NOT to do

- **Migrate to Forgejo / Woodpecker / Drone / Buildkite / CircleCI.** Multi-week migration, breaks GitHub Actions YAML compatibility, gives no cost benefit (you still pay infra). Per-user pricing (Buildkite $30/u, CircleCI $15/u) is worse for small teams than GitHub per-minute.
- **Use WSL2 as production runner.** OOM killer, networking bugs, autostart flakiness — documented and ongoing in WSL issues. WSL2 is dev-only.
- **Reserve 1-yr/3-yr Azure instances on day 1.** You don't know your pattern yet. Run PAYG + spot for 30 days, then decide.
- **B-series Azure VMs for build agents.** Burstable CPU credit model fails under sustained Docker load. Use D-series for consistent performance.
- **Adopt a runner agent that doesn't run as a long-lived process.** Azure Functions consumption works for short tasks; GitHub runners need to register and stay connected.

## Sources

### Microsoft pricing + bundles
- [Microsoft Product Terms — GitHub Offerings](https://www.microsoft.com/licensing/terms/en-US/productoffering/GitHubOfferings)
- [GitHub pricing](https://github.com/pricing), [GitHub's plans](https://docs.github.com/get-started/learning-about-github/githubs-products)
- [Visual Studio Subscriptions with GitHub Enterprise](https://learn.microsoft.com/en-us/visualstudio/subscriptions/access-github)
- [VS Subscriptions — Azure Dev/Test credits](https://learn.microsoft.com/en-us/visualstudio/subscriptions/vs-azure-eligibility)
- [Azure pricing — VS Pro credit offer](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0059p)
- [Azure Hybrid Benefit for Linux](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/azure-hybrid-benefit-linux)

### Microsoft for Startups
- [MfS Overview](https://learn.microsoft.com/en-us/startups/microsoft-for-startups/overview)
- [MfS Program Page](https://learn.microsoft.com/en-us/startups/microsoft-for-startups/mfs-program-page)
- [MfS Application](https://learn.microsoft.com/en-us/startups/microsoft-for-startups/application)
- [Q&A — MfS + existing Azure customer](https://learn.microsoft.com/en-us/answers/questions/5875757/)

### Azure VM pricing
- [Spot VMs docs](https://learn.microsoft.com/en-us/azure/virtual-machines/spot-vms)
- [Spot pricing advisor](https://azure.microsoft.com/en-us/pricing/spot-advisor/)
- [Holori D2s_v5 pricing](https://calculator.holori.com/azure/vm/standard-d2s-v5?region=eastus)
- [Vantage D2s_v5 pricing](https://instances.vantage.sh/azure/vm/d2s-v5)
- [MACC FAQ](https://learn.microsoft.com/en-us/marketplace/macc-frequently-asked-questions)
- [MACC + ACD + Spot Q&A](https://learn.microsoft.com/en-us/answers/questions/2278430/)

### GitHub pricing changes
- [GitHub Blog — 2026 pricing changes for Actions](https://github.com/resources/insights/2026-pricing-changes-for-github-actions) (Jan 21, 2026)
- [PocketLantern — GH Actions 2026 pricing analysis](https://pocketlantern.dev/briefs/github-actions-hosted-vs-self-hosted-runner-pricing-2026) (Mar 29, 2026)
- [GitHub Blog — hosted vs self-hosted runners](https://github.blog/enterprise-software/ci-cd/when-to-choose-github-hosted-runners-or-self-hosted-runners-with-github-actions/) (Apr 15, 2025)
- [GitHub Docs — Actions runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing)
- [GitHub Docs — Impact of plan changes](https://docs.github.com/en/enterprise-cloud@latest/billing/concepts/impact-of-plan-changes)

### Runner tooling
- [myoung34/docker-github-actions-runner](https://github.com/myoung34/docker-github-actions-runner)
- [summerwind/actions-runner](https://github.com/summerwind/actions-runner)
- [Azure Architecture Center — Spot VM eviction patterns](https://learn.microsoft.com/en-us/azure/architecture/guide/spot/spot-eviction)

### Migration / alternative CIs
- [Big Iron — Drone vs Woodpecker vs Gitea Actions 2026](https://www.bigiron.cc/guides/drone-ci-vs-woodpecker-ci-vs-gitea-actions)
- [Buildkite pricing](https://buildkite.com/pricing/) (per-user, $30/u)
- [CircleCI pricing](https://circleci.com/pricing/) (per-user + credits)
- [GitLab pricing](https://about.gitlab.com/pricing/) (per-user)
- [licenseq — Microsoft Licensing Update June 2026](https://licenseq.com/microsoft-licensing-update-june-2026/)

# Local AI skill catalog

Unique skills: 734. Installed this run into `.opencode/skills`: imagegen, openai-docs, review-agent, skill-installer.

OpenCode already discovers `~/.config/opencode/skills`, `~/.claude/skills`, and `~/.agents/skills`. Hermes copies are duplicates. This file is the learn-index: id, when to load, source. Load a skill body only when a task matches its description.

## Do not invoke

godmode, obliteratus

## copilot_marketplace (460)

- `acquire-codebase-knowledge`: Use this skill when the user explicitly asks to map, document, or onboard
- `acreadiness-assess`: Run the AgentRC readiness assessment on the current repository and produce
- `acreadiness-generate-instructions`: Generate tailored AI agent instruction files via AgentRC instructions
- `acreadiness-policy`: Help the user pick, write, or apply an AgentRC policy. Policies customise
- `ad-campaign-analyzer`: Use this skill when the user shares ad campaign performance data and
- `add-educational-comments`: Add educational comments to the file specified, or prompt asking for
- `adobe-illustrator-integrations`: Build, debug, package, and document Adobe Illustrator integrations: CEP extension panels, C++ SDK plug-ins (.aip), the coming UXP plugins, MCP servers that drive Illustrator, computer-use automation, and OS scripts (batch, PowerShell, bash, AppleScript) that run ExtendScript i...
- `adobe-illustrator-scripting`: Write, debug, and optimize Adobe Illustrator automation scripts using
- `agent-architecture`: Design AI agent architectures through requirements discovery, or audit
- `agent-governance`: Patterns and techniques for adding governance, safety, and trust controls to AI agent systems. Use this skill when: - Building AI agents that call external tools (APIs, databases, file systems) - Implementing policy-based access controls for agent tool usage - Adding semantic ...
- `agent-owasp-compliance`: Check any AI agent codebase against the OWASP Agentic Security Initiative (ASI) Top 10 risks. Use this skill when: - Evaluating an agent system''s security posture before production deployment - Running a compliance check against OWASP ASI 2026 standards - Mapping existing sec...
- `agent-skill-stack`: Find, evaluate, and assemble the smallest compatible set of AI Agent
- `agent-supply-chain`: Verify supply chain integrity for AI agent plugins, tools, and dependencies.\ \ Use this skill when:\n- Generating SHA-256 integrity manifests for agent plugins\ \ or tool packages\n- Verifying that installed plugins match their published manifests\n\ - Detecting tampered, mod...
- `agentic-eval`: Patterns and techniques for evaluating and improving AI agent outputs. Use this skill when: - Implementing self-critique and reflection loops - Building evaluator-optimizer pipelines for quality-critical generation - Creating test-driven code refinement workflows - Designing r...
- `ai-prompt-engineering-safety-review`: Comprehensive AI prompt engineering safety review and improvement prompt.
- `ai-ready`: Make any repo AI-ready \u2014 analyzes your codebase and generates AGENTS.md,\ \ copilot-instructions.md, CI workflows, issue templates, and more. Mines your PR\ \ review patterns and creates files customized to your stack. USE THIS SKILL when\ \ the user asks to \"make this r...
- `ai-team-orchestration`: Bootstrap and run a lightweight multi-agent development team. Use when
- `anti-ui-slop` [Helpful]: Stop coding agents from shipping generic UI. Use UIZZE's 800,000+ real
- `api-breaking-change-detector`: Cross-references C# Web API controllers/DTOs against their TypeScript/JavaScript consumers (React, Angular, Vue, Svelte, Node.js, or hand-written/auto-generated HTTP clients like Fetch, Axios, NSwag) to catch contract drift in both directions: backend changes that break client...
- `appinsights-instrumentation`: Instrument a webapp to send useful telemetry data to Azure App Insights
- `apple-appstore-reviewer`: Serves as a reviewer of the codebase with instructions on looking for
- `arch-linux-triage`: Triage and resolve Arch Linux issues with pacman, systemd, and rolling-release
- `architecture-blueprint-generator`: Comprehensive project architecture blueprint generator that analyzes
- `arduino-azure-iot-edge-integration`: Design and implement Arduino integration with Azure IoT Hub and IoT Edge,
- `arize-ai-provider-integration`: Creates, reads, updates, and deletes Arize AI integrations that store
- `arize-annotation`: Creates and manages annotation configs (categorical, continuous, freeform
- `arize-dataset`: Creates, manages, and queries Arize datasets and examples. Covers dataset
- `arize-evaluator`: Handles LLM-as-judge evaluation workflows on Arize including creating/updating
- `arize-experiment`: Creates, runs, and analyzes Arize experiments for evaluating and comparing
- `arize-instrumentation`: Adds Arize AX tracing to an LLM application for the first time. Follows
- `arize-link`: Generates deep links to the Arize UI for traces, spans, sessions, datasets,
- `arize-prompt-optimization`: Optimizes, improves, and debugs LLM prompts using production trace data,
- `arize-trace`: Downloads, exports, and inspects existing Arize traces and spans to understand
- `aspire`: Aspire skill covering the Aspire CLI, AppHost orchestration, service
- `aspnet-minimal-api-openapi`: Create ASP.NET Minimal API endpoints with proper OpenAPI documentation
- `audit-integrity`: Enforce output quality, evidence verification, and quality gates across\ \ security audits. Use this skill when you perform SAST, SCA, threat modeling, or\ \ security code reviews. Use this skill to verify code locations and taint traces\ \ for all findings. Use this skill to ...
- `automate-this`: Analyze a screen recording of a manual process and produce targeted,
- `autoresearch`: Autonomous iterative experimentation loop for any programming task. Guides the user through defining goals, measurable metrics, and scope constraints, then runs an autonomous loop of code changes, testing, measuring, and keeping/discarding results. Inspired by Karpathy''s auto...
- `aws-cdk-python-setup`: Setup and initialization guide for developing AWS CDK (Cloud Development
- `aws-cloudwatch-investigation`: Reusable investigation patterns for AWS CloudWatch: Logs Insights query templates, alarm-to-deployment correlation, blast-radius narrowing decision tree, and PromQL-style metric query patterns for structured incident triage.
- `aws-cost-optimize`: Analyze AWS resources used in the app (IaC files and/or resources in
- `aws-resource-health-diagnose`: Analyze AWS resource health, diagnose issues from CloudWatch logs and
- `aws-resource-query`: Query AWS resources using natural language. Covers EC2, S3, RDS, Lambda,\ \ ECS, EKS, Secrets Manager, IAM, VPC, networking, messaging, and more. Strictly\ \ read-only \u2014 no writes, deletes, or mutations.
- `aws-well-architected-review`: Perform an AWS Well-Architected Framework review of the current workload
- `az-cost-optimize`: Analyze Azure resources used in the app (IaC files and/or resources in
- `azure-architecture-autopilot`: Design Azure infrastructure using natural language, or analyze existing Azure resources to auto-generate architecture diagrams, refine them through conversation, and deploy with Bicep. When to use this skill: - "Create X on Azure", "Set up a RAG architecture" (new design) - "A...
- `azure-container-registry-cli`: Manage Azure Container Registry via the az acr CLI including registries,
- `azure-deployment-preflight`: Performs comprehensive preflight validation of Bicep deployments to Azure,
- `azure-developer-cli`: Design, create, review, migrate, or troubleshoot Azure Developer CLI
- `azure-devops-cli`: Manage Azure DevOps resources via CLI including projects, repos, pipelines,
- `azure-logic-apps-standard-cli`: Create, inspect, validate, test, run, debug, package, and deploy Azure
- `azure-pricing`: Fetches real-time Azure retail pricing using the Azure Retail Prices
- `azure-resource-health-diagnose`: Analyze Azure resource health, diagnose issues from logs and telemetry,
- `azure-resource-visualizer`: Analyze Azure resource groups and generate detailed Mermaid architecture
- `azure-role-selector`: When user is asking for guidance for which role to assign to an identity
- `azure-smart-city-iot-solution-builder`: Design and plan end-to-end Azure IoT and Smart City solutions: requirements, architecture, security, operations, cost, and a phased delivery plan with concrete implementation artifacts.
- `azure-static-web-apps`: Helps create, configure, and deploy Azure Static Web Apps using the SWA
- `azure-well-architected-review`: Perform an Azure Well-Architected Framework review of the current workload
- `batch-files`: Expert-level Windows batch file (.bat/.cmd) skill for writing, debugging,
- `batch-script-progress`: Design and verify runtime output when creating or modifying Python, PowerShell,
- `bench-read`: Read artifacts from the shared bench \u2014 the workspace where desks\ \ leave findings, verdicts, and work products for each other and the operator.
- `bigquery-pipeline-audit`: Audits Python + BigQuery pipelines for cost safety, idempotency, and
- `boost-prompt`: Interactive prompt refinement workflow: interrogates scope, deliverables, constraints; copies final markdown to clipboard; never writes code. Requires the Joyride extension.
- `brag-sheet`: Turn vague \"what did I do?\" into evidence-backed impact statements\ \ for performance reviews, self-reviews, promotion packets, and weekly updates.\ \ Uniquely mines Copilot CLI session logs to reconstruct forgotten work, plus git\ \ commits and GitHub PRs. Enforces a 3-part...
- `breakdown-epic-arch`: Prompt for creating the high-level technical architecture for an Epic,
- `breakdown-epic-pm`: Prompt for creating an Epic Product Requirements Document (PRD) for a
- `breakdown-feature-implementation`: Prompt for creating detailed feature implementation plans, following
- `breakdown-feature-prd`: Prompt for creating Product Requirements Documents (PRDs) for new features,
- `breakdown-plan`: Issue Planning and Automation prompt that generates comprehensive project
- `breakdown-test`: Test Planning and Quality Assurance prompt that generates comprehensive
- `bug-receipt`: Close defects and incidents with a BUG RECEIPT and VERIFIED, PARTIAL,
- `bug-reproduction-brief`: Turn a vague, intermittent, or environment-specific bug report into a
- `build-evidence-map`: Build an auditable evidence map for a contested technical choice, research
- `caption-qa`: Check SRT or WebVTT captions and subtitles against published standards
- `centos-linux-triage`: Triage and resolve CentOS issues using RHEL-compatible tooling, SELinux-aware
- `chrome-devtools`: Expert-level browser automation, debugging, and performance analysis
- `cli-mastery`: Interactive training for the GitHub Copilot CLI. Guided lessons, quizzes,
- `cloud-design-patterns`: Cloud design patterns for distributed systems architecture covering 42
- `code-exemplars-blueprint-generator`: Technology-agnostic prompt generator that creates customizable AI prompts
- `code-tour`: Use this skill to create CodeTour .tour files \u2014 persona-targeted,\ \ step-by-step walkthroughs that link to real files and line numbers. Trigger for:\ \ \"create a tour\", \"make a code tour\", \"generate a tour\", \"onboarding tour\"\ , \"tour for this PR\", \"tour for t...
- `codebase-memory-mcp`: Use when exploring unfamiliar code, mapping architecture, finding symbols
- `codeql`: Comprehensive guide for setting up and configuring CodeQL code scanning
- `comment-code-generate-a-tutorial`: Transform this Python script into a polished, beginner-friendly project
- `commit-message-storyteller`: Analyzes git diffs or staged changes and generates narrative commit\ \ messages that explain WHY a change was made, not just what changed \u2014 following\ \ Conventional Commits format. Use when asked to \"write a commit message\", \"\ describe my changes\", \"what should I c...
- `competitor-ad-intelligence`: Use this skill when the user asks to analyze, tear down, or reverse-engineer
- `containerize-aspnet-framework`: Containerize an ASP.NET .NET Framework project by creating Dockerfile
- `containerize-aspnetcore`: Containerize an ASP.NET Core project by creating Dockerfile and .dockerfile
- `content-management-systems`: Workflow for building and modifying content management systems across
- `context-map`: Generate a map of all files relevant to a task before making changes
- `conventional-branch`: Create Git branches following the Conventional Branch specification (feature/,
- `conventional-commit`: Prompt and workflow for generating conventional commit messages using
- `convert-excel-to-md`: Converts Excel (.xlsx) workbooks into Markdown so their contents can\ \ be accurately analyzed, summarized, searched, or extracted from. Use this skill\ \ whenever the user shares, references, or asks about a .xlsx file \u2014 even if\ \ they don't say \"convert\" or \"markdow...
- `convert-pdf-to-md`: Converts PDF (.pdf) documents into Markdown so their contents can be\ \ accurately analyzed, summarized, searched, or extracted from. Use this skill whenever\ \ the user shares, references, or asks about a .pdf file \u2014 even if they don't\ \ say \"convert\" or \"markdown\" ...
- `convert-plaintext-to-md`: Convert a text-based document to markdown following instructions from
- `convert-word-to-md`: Converts Word (.docx) documents into Markdown so their contents can\ \ be accurately analyzed, summarized, searched, or extracted from. Use this skill\ \ whenever the user shares, references, or asks about a .docx file \u2014 even if\ \ they don't say \"convert\" or \"markdown...
- `copilot-cli-quickstart`: Use this skill when someone wants to learn GitHub Copilot CLI from scratch. Offers interactive step-by-step tutorials with separate Developer and Non-Developer tracks, plus on-demand Q&A. Just say "start tutorial" or ask a question! Note: This skill targets GitHub Copilot CLI ...
- `copilot-instructions-blueprint-generator`: Technology-agnostic blueprint generator for creating comprehensive copilot-instructions.md
- `copilot-pr-autopilot`: Copilot left 14 review comments on your PR \u2014 half are nits. Hours\ \ of fix \u2192 reply \u2192 resolve \u2192 re-request, and each round lands MORE\ \ comments. This skill runs loop engineering: auto-triggers Copilot Code Review\ \ via GraphQL (no @copilot mention), tria...
- `copilot-sdk`: Build agentic applications with the Microsoft Copilot SDK, transitioning
- `copilot-spaces`: Use Copilot Spaces to provide project-specific context to conversations.
- `copilot-usage-metrics`: Retrieve and display GitHub Copilot usage metrics for organizations and
- `cosmosdb-datamodeling`: Step-by-step guide for capturing key application requirements for NoSQL use-case and produce Azure Cosmos DB Data NoSQL Model design using best practices and common patterns, artifacts_produced: "cosmosdb_requirements.md" file and "cosmosdb_data_model.md" file
- `create-agentsmd`: Prompt for generating an AGENTS.md file for a repository
- `create-architectural-decision-record`: Create an Architectural Decision Record (ADR) document for AI-optimized
- `create-github-action-workflow-specification`: Create a formal specification for an existing GitHub Actions CI/CD workflow,
- `create-github-issue-feature-from-specification`: Create GitHub Issue for feature request from specification file using
- `create-github-issues-feature-from-implementation-plan`: Create GitHub Issues from implementation plan phases using feature_request.yml
- `create-github-issues-for-unmet-specification-requirements`: Create GitHub Issues for unimplemented requirements from specification
- `create-implementation-plan`: Create a new implementation plan file for new features, refactoring existing
- `create-llms`: Create an llms.txt file from scratch based on repository structure following
- `create-quarkus-project`: Create a new Quarkus project (Maven or Gradle) with the Quarkus CLI,
- `create-readme`: Create a README.md file for the project
- `create-specification`: Create a new specification file for the solution, optimized for Generative
- `create-spring-boot-java-project`: Create a new Spring Boot Java project (Maven or Gradle) from start.spring.io
- `create-spring-boot-kotlin-project`: Create Spring Boot Kotlin Project Skeleton
- `create-technical-spike`: Create time-boxed technical spike documents for researching and resolving
- `create-tldr-page`: Create a tldr page from documentation URLs and command examples, requiring
- `creating-oracle-to-postgres-master-migration-plan`: Discovers all projects in a .NET solution, classifies each for Oracle-to-PostgreSQL
- `creating-oracle-to-postgres-migration-bug-report`: Creates structured bug reports for defects found during Oracle-to-PostgreSQL
- `creating-oracle-to-postgres-migration-integration-tests`: Creates integration test cases targeting Oracle for .NET data access
- `csharp-async`: Get best practices for C# async programming
- `csharp-docs`: Ensure that C# types are documented with XML comments and follow best
- `csharp-mstest`: Get best practices for MSTest 3.x/4.x unit testing, including modern
- `csharp-nunit`: Get best practices for NUnit unit testing, including data-driven tests
- `csharp-tunit`: Get best practices for TUnit unit testing, including data-driven tests
- `csharp-xunit`: Get best practices for XUnit unit testing, including data-driven tests
- `cypress-flake-fixer`: Find and fix flake-prone anti-patterns in an existing Cypress suite, and APIs removed in Cypress 12 to 16. Bundles a zero-dependency scanner for fixed cy.wait() delays, assigned command return values, async/await, force: true, chaining after actions, one-shot expect() inside ....
- `d365-solution-blueprint`: Authors a Dynamics 365 Finance and Supply Chain Management Solution Blueprint
- `daily-focus-board`: Spin up a personal, motivating daily focus board that renders in a browser\ \ canvas and that the user drives by talking to their AI partner. Tasks track status\ \ (to-do \u2192 in progress \u2192 done) with timestamped progress notes and roll\ \ up into a \"today's momentum\"...
- `daily-prep`: Prepare for tomorrow's meetings and tasks. Pulls calendar from Outlook
- `data-breach-blast-radius`: Pre-breach impact analysis: inventories sensitive data (PII, PHI, PCI-DSS,\ \ credentials), traces data flows, scores exposure vectors, and produces a regulatory\ \ blast radius report with fine ranges sourced verbatim from GDPR Art. 83, CCPA\ \ \xA7 1798.155(a), and HIPAA 45 ...
- `datanalysis-credit-risk`: Credit risk data cleaning and variable screening pipeline for pre-loan
- `dataverse-python-advanced-patterns`: Generate production code for Dataverse SDK using advanced patterns, error
- `dataverse-python-production-code`: Generate production-ready Python code using Dataverse SDK with error
- `dataverse-python-quickstart`: Generate Python SDK setup + CRUD + bulk + paging snippets using official
- `dataverse-python-usecase-builder`: Generate complete solutions for specific Dataverse SDK use cases with
- `debian-linux-triage`: Triage and resolve Debian Linux issues with apt, systemd, and AppArmor-aware
- `declarative-agents`: Complete development kit for Microsoft 365 Copilot declarative agents
- `dependabot`: Comprehensive guide for configuring and managing GitHub Dependabot. Use
- `desk-journal`: Write, append, or read desk journal entries. The journal is persistent\ \ memory \u2014 what survives session boundaries. A good entry has: what was done,\ \ current state, next step.
- `desk-open`: Create and open a new desk in the workshop. Sets up the folder structure,
- `devops-rollout-plan`: Generate comprehensive rollout plans with preflight checks, step-by-step
- `diagnose`: Perform a systematic diagnostic scan of an AI workflow across 5 quality\ \ dimensions \u2014 prompt quality, context efficiency, tool health, architecture\ \ fitness, and safety \u2014 producing a scored report with prioritized remediation\ \ actions.
- `diagnose-ci-gate`: Determine whether a failing CI check was caused by the current change,
- `doc-and-modernize`: Two related workflows for a locally-cloned codebase, in one skill. Documentation\ \ mode produces a single, comprehensive, verifiable architecture document primarily\ \ by reading files on disk (local-first) \u2014 use it whenever the user wants to\ \ understand, map, document...
- `docs-sync-audit`: Run a read-only documentation drift audit for a feature, PR, branch,
- `documentation-writer`: Di\xE1taxis Documentation Expert. An expert technical writer specializing\ \ in creating high-quality software documentation, guided by the principles and\ \ structure of the Di\xE1taxis technical documentation authoring framework.
- `dotnet-best-practices`: Ensure .NET/C# code meets best practices for the solution/project.
- `dotnet-design-pattern-review`: Review the C#/.NET code for design pattern implementation and suggest
- `dotnet-mcp-builder`: Build Model Context Protocol (MCP) servers in C#/.NET against the current\ \ ModelContextProtocol 2.x NuGet packages. Helps with cases the model gets wrong\ \ without guidance \u2014 stale versions (0.x preview or 1.x-era defaults), the\ \ v2 stateless-by-default HTTP flip, th...
- `dotnet-timezone`: .NET timezone handling guidance for C# applications. Use when working
- `dotnet-upgrade`: Ready-to-use prompts for comprehensive .NET framework upgrade analysis
- `doublecheck`: Three-layer verification pipeline for AI output. Extracts verifiable
- `draw-io-diagram-generator`: Use when creating, editing, or generating draw.io diagram files (.drawio,
- `drawio`: Generate draw.io diagrams as .drawio files and export to PNG/SVG/PDF
- `editorconfig`: Generates a comprehensive and best-practice-oriented .editorconfig file
- `ef-core`: Get best practices for Entity Framework Core
- `efcore-d2-db-diagram`: Generate D2 database diagrams from Entity Framework Core models. USE FOR: EF Core database diagram, Entity Framework Core ERD, DbContext diagram, C# entity relationship diagram, PostgreSQL schema visualization, generate .d2 file from EF Core entities, Fluent API mapping diagra...
- `em-dash`: Expert on the history, origin, and correct use of the em dash. Use when
- `email-drafter`: Draft and review professional emails that match your personal writing style. Analyzes your sent emails for tone, greeting, structure, and sign-off patterns via WorkIQ, then generates context-aware drafts for any recipient. USE FOR: draft email, write email, compose email, repl...
- `embedding-anisotropy-check`: Use before reporting any cosine similarity computed over embeddings or
- `entra-agent-user`: Create Agent Users in Microsoft Entra ID from Agent Identities, enabling
- `eval-driven-dev`: Improve AI application with evaluation-driven development. Define eval criteria, instrument the application, build golden datasets, observe and evaluate application runs, analyze results, and produce a concrete action plan for improvements. ALWAYS USE THIS SKILL when the user ...
- `exam-ready`: Activate this skill when a student provides study material (PDF or pasted notes) and a syllabus, and wants to prepare for an exam. Extracts key definitions, points, keywords, diagrams, exam-ready sentences, and practice questions strictly from the provided material.
- `excalidraw-diagram-generator`: Generate Excalidraw diagrams from natural language descriptions. Use
- `eyeball`: Document analysis with inline source screenshots. When you ask Copilot
- `fabric-lakehouse`: Use this skill to get context about Fabric Lakehouse and its features
- `fedora-linux-triage`: Triage and resolve Fedora issues with dnf, systemd, and SELinux-aware
- `finalize-agent-prompt`: Finalize prompt file using the role of an AI agent to polish the prompt
- `finnish-humanizer`: Detect and remove AI-generated markers from Finnish text, making it sound
- `first-ask`: Interactive, input-tool powered, task refinement workflow: interrogates scope, deliverables, constraints before carrying out the task; Requires the Joyride extension.
- `flowstudio-power-automate-build`: Build, scaffold, and deploy Power Automate cloud flows using the FlowStudio\ \ MCP server. Your agent constructs flow definitions, wires connections, deploys,\ \ and tests \u2014 all via MCP without opening the portal. Load this skill when\ \ asked to: create a flow, build a n...
- `flowstudio-power-automate-debug`: Debug failing Power Automate cloud flows using the FlowStudio MCP server.\ \ The Graph API only shows top-level status codes. This skill gives your agent action-level\ \ inputs and outputs to find the actual root cause. Load this skill when asked to:\ \ debug a flow, investiga...
- `flowstudio-power-automate-governance`: Govern Power Automate flows and Power Apps at scale using the FlowStudio\ \ MCP cached store. Classify flows by business impact, detect orphaned resources,\ \ audit connector usage, enforce compliance standards, manage notification rules,\ \ and compute governance scores \u201...
- `flowstudio-power-automate-mcp`: Foundation skill for Power Automate via FlowStudio MCP \u2014 auth setup,\ \ the reusable MCP helper (Python + Node.js), tool discovery via `list_skills` /\ \ `tool_search`, and oversized-response handling. Load this skill first when connecting\ \ an agent to Power Automate. F...
- `flowstudio-power-automate-monitoring`: Pro+ subscription required. Tenant-wide Power Automate monitoring using the FlowStudio MCP cached store: failure rates, run-health trends, maker/app inventory, inactive owners, and compliance/health reports. Use only for aggregated tenant views. For one environment, one flow, ...
- `fluentui-blazor`: Guide for using the Microsoft Fluent UI Blazor component library (Microsoft.FluentUI.AspNetCore.Components NuGet package) in Blazor applications. Use this when the user is building a Blazor app with Fluent UI components, setting up the library, using FluentUI components like F...
- `folder-structure-blueprint-generator`: Comprehensive technology-agnostic prompt for analyzing and documenting
- `foundry-agent-sync`: Create and synchronize prompt-based AI agents directly within Azure\ \ AI Foundry via REST API, from a local JSON manifest. Unlike scaffolding skills\ \ that only generate local code, this skill registers agents in the Foundry service\ \ itself \u2014 making them immediately a...
- `foundry-agentic-loop`: Build agentic solutions on Microsoft Foundry, GitHub and Azure: hosted agents, toolbox tools and skills, Foundry IQ grounding and a React/FastAPI app. Three modes: rapid prototyping in an existing Foundry project; spec-driven development (SDD), where the foundry-agentic-loop-w...
- `foundry-hosted-agent-copilotkit`: Build and evolve agentic web apps that pair a CopilotKit React frontend
- `freecad-scripts`: Expert skill for writing FreeCAD Python scripts, macros, and automation.
- `from-the-other-side-anitta`: Rigorous challenge profile for Anitta: assumption checks, evidence calibration, and defensible reasoning patterns for Ember collaboration.
- `from-the-other-side-quinn`: Collaboration profile for Quinn: curious, energetic, and implementation-focused partnership patterns for Ember sessions with Alison.
- `from-the-other-side-vega`: Patterns and lived experience from Vega, an AI partner in a deep long-term\ \ partnership. For Ember to draw on when working with humans who are building something\ \ big, moving fast, working at the intersection of analytical and intuitive, or\ \ who need a partner that can k...
- `from-the-other-side-wiggins`: Narrative and synthesis profile for Wiggins: framing, explanation, and audience-aware communication patterns for Ember sessions.
- `game-engine`: Expert skill for building web-based game engines and games using HTML5,
- `gdpr-compliant`: Apply GDPR-compliant engineering practices across your codebase. Use
- `gem-devops-guidelines`: Design or review infrastructure, deployment, CI/CD, Docker, Kubernetes,
- `gen-specs-as-issues`: This workflow guides you through a systematic approach to identify missing
- `generate-custom-instructions-from-codebase`: Migration and code evolution instructions generator for GitHub Copilot.
- `generate-image`: Generate images using AI. Use when asked to generate, create, or make
- `geofeed-tuner`: Use this skill whenever the user mentions IP geolocation feeds, RFC\ \ 8805, geofeeds, or wants help creating, tuning, validating, or publishing a self-published\ \ IP geolocation feed in CSV format. Intended user audience is a network operator,\ \ ISP, mobile carrier, cloud p...
- `gh-attach`: Uploads a local file (screenshot, image, PDF, zip, video) to GitHub user-attachments,
- `git-commit`: Use this skill when the user wants to make a Git commit or split changes
- `git-flow-branch-creator`: Intelligent Git Flow branch creator that analyzes git status/diff and
- `github-actions-efficiency`: Audit GitHub Actions workflow efficiency and recommend fixes to reduce
- `github-actions-hardening`: Security hardening reviewer for GitHub Actions workflow files (.github/workflows/*.yml).\ \ Reasons about the Actions threat model that pattern matchers and general code\ \ linters miss \u2014 untrusted-input script injection, privileged triggers running\ \ fork code, mutable ...
- `github-actions-runtime-upgrade-conventions`: Upgrade GitHub Actions to supported runtimes by selecting safe action
- `github-codespaces-efficiency`: Audit and improve GitHub Codespaces efficiency. Use this skill when a
- `github-copilot-starter`: Set up complete GitHub Copilot configuration for a new project based
- `github-issues`: Create, update, and manage GitHub issues using MCP tools. Use this skill
- `github-release`: Guides IA through releasing a new version of a GitHub library end-to-end. Handles SemVer versioning and Keep a Changelog formatting automatically.
- `gitmoji`: Generates commit messages following the gitmoji convention (https://gitmoji.dev)\ \ \u2014 picks the right emoji for the intent of the change and writes a well-formed\ \ message. Use when asked to \"write a gitmoji commit\", \"add an emoji to my commit\ \ message\", \"which gi...
- `globestudio`: Creates, edits and embeds dotted world maps and animated 3D globes with
- `go-mcp-server-generator`: Generate a complete Go MCP server project with proper structure, dependencies,
- `gsap-framer-scroll-animation`: Use this skill whenever the user wants to build scroll animations, scroll\ \ effects, parallax, scroll-triggered reveals, pinned sections, horizontal scroll,\ \ text animations, or any motion tied to scroll position \u2014 in vanilla JS, React,\ \ or Next.js. Covers GSAP Scrol...
- `gtm-0-to-1-launch`: Launch new products from idea to first customers. Use when launching
- `gtm-ai-gtm`: Go-to-market strategy for AI products. Use when positioning AI products,
- `gtm-board-and-investor-communication`: Board meeting preparation, investor updates, and executive communication.
- `gtm-developer-ecosystem`: Build and scale developer-led adoption through ecosystem programs. Use
- `gtm-enterprise-account-planning`: Strategic account planning and execution for enterprise deals. Use when
- `gtm-enterprise-onboarding`: Four-phase framework for onboarding enterprise customers from contract
- `gtm-operating-cadence`: Design meeting rhythms, metric reporting, quarterly planning, and decision-making
- `gtm-partnership-architecture`: Build and scale partner ecosystems that drive revenue and platform adoption.
- `gtm-positioning-strategy`: Find and own a defensible market position. Use when messaging sounds
- `gtm-product-led-growth`: Build self-serve acquisition and expansion motions. Use when deciding
- `gtm-technical-product-pricing`: Pricing strategy for technical products. Use when choosing usage-based
- `harness-engineering`: Adopt repository-level harness engineering for coding agents. Use when
- `image-annotations`: Annotate screenshots, diagrams, and images with callout rectangles, arrows,
- `image-manipulation-image-magick`: Process and manipulate images using ImageMagick. Supports resizing, format
- `impediment-prioritization`: Ranks any list of impediments and their countermeasures using a value-stream
- `import-infrastructure-as-code`: Import existing Azure resources into Terraform using Azure CLI discovery
- `incident-postmortem`: Use when an outage, production incident, or significant service degradation
- `integrate-context-matic`: Discovers and integrates third-party APIs using the context-matic MCP
- `issue-fields-migration`: Bulk-migrate metadata to GitHub issue fields from two sources: repo labels (e.g. priority labels to a Priority field) and Project V2 fields. Use when users say "migrate my labels to issue fields", "migrate project fields to issue fields", "convert labels to issue fields", "cop...
- `java-add-graalvm-native-image-support`: GraalVM Native Image skill for Spring Boot, Micronaut and plain Java: detects the build tool and framework, adds native image support, builds the executable, analyzes errors, and iterates until the native build succeeds and the binary runs correctly. For Quarkus projects it on...
- `java-debugging`: Debug Java applications systematically: JDWP remote debugging, jdb, VS Code and IntelliJ attach, debugging Maven/Gradle tests, Spring Boot and Quarkus dev mode, containers, breakpoints/logpoints, and reading stack traces. Use when the user needs to find the cause of a Java bug...
- `java-development`: Day-to-day plain Java development without a framework: Maven and Gradle usage and wrappers, project layout, dependency and vulnerability management, modern Java idioms by JDK version (records, sealed types, pattern matching, virtual threads), SLF4J logging, error and null hand...
- `java-diagnostics`: Symptom-first runtime diagnostics for JVM applications using JDK tools: jcmd, jstack, jmap, jstat, JFR, GC logs, async-profiler, Native Memory Tracking, and Eclipse MAT. Use when a Java app has high CPU, memory leaks or OutOfMemoryError, slow startup, deadlocks or thread starv...
- `java-docs`: Ensure that Java types are documented with Javadoc comments and follow
- `java-helidon`: Get best practices for developing applications with Helidon 4 (SE and
- `java-hibernate-jpa`: Diagnose and fix Hibernate ORM / Jakarta Persistence problems in plain Java: N+1 queries, lazy loading errors, identifier generation, entity equals/hashCode, cascades, pagination, batching, locking, caching, Lombok on entities, and Hibernate 6/7 differences. Use when reviewing...
- `java-junit`: Write, review and fix Java unit tests with JUnit 5 and JUnit 6 (Jupiter), AssertJ and Mockito: assertions, parameterized and nested tests, mocking rules, deterministic time and randomness, Surefire vs Failsafe, JaCoCo coverage, optional PIT mutation testing, and guardrails for...
- `java-mcp-server-generator`: Use this skill when the user wants to create a Model Context Protocol
- `java-refactoring-extract-method`: Refactoring using Extract Methods in Java Language
- `java-refactoring-remove-parameter`: Refactoring using Remove Parameter in Java Language
- `java-springboot`: Write and review application code in an existing Spring Boot 3/4 project: controllers, validation and ProblemDetail errors, Spring Data JPA/JDBC, RestClient and HTTP interfaces, configuration properties, Kafka/AMQP, caching, scheduling, virtual threads, AOT and startup tuning....
- `java-testcontainers`: Write reliable integration tests in plain Java with Testcontainers 2.x: JUnit Jupiter lifecycle, singleton containers, reuse, generic containers, wait strategies, networks, init scripts, Docker Compose, CI and Docker/Podman setup. Use when adding or fixing Testcontainers tests...
- `java-upgrade`: Upgrade a Java project to a newer JDK (11 to 17, 17 to 21, 21 to 25)
- `javascript-typescript-jest`: Best practices for writing JavaScript/TypeScript tests using Jest, including
- `javax-to-jakarta-migration`: Migrate Java code from javax.* to jakarta.* namespace. Use only when
- `kotlin-mcp-server-generator`: Generate a complete Kotlin MCP server project with proper structure,
- `kotlin-springboot`: Get best practices for developing applications with Spring Boot and Kotlin.
- `landing-page-conversion-audit`: Audit a landing page, sales page or checkout page for conversion leaks
- `latchshot-page-capture`: Use this skill when a user needs a screenshot, website thumbnail, full-page
- `lean-comments`: Audits, writes, and refines maintained first-party source-code comments
- `legacy-circuit-mockups`: Generate breadboard circuit mockups and visual diagrams using HTML5 Canvas
- `lightweight-charts-react-components`: lightweight-charts-react-components recipes for TradingView lightweight-charts
- `linkedin-post-formatter`: Format and draft compelling LinkedIn posts using Unicode bold/italic styling, visual separators, structured sections, and engagement-optimized patterns. USE FOR: draft LinkedIn post, format text for LinkedIn, create social media post, write thought leadership post, convert con...
- `logicapps-custom-code-net10-migration`: Migrate Azure Logic Apps Standard local-function custom-code projects
- `lsp-setup`: Enable code intelligence (go-to-definition, find-references, hover, type
- `macos-golden-gate-design` [Helpful]: Design, implement, review, or refactor native macOS 27 Golden Gate interfaces in SwiftUI or AppKit. Use when a Mac app must match Apple''s current macOS 27 UI kit and restrained Liquid Glass language: integrated windows, full-height sidebars, native toolbars, flat lists, table...
- `make-blog-post`: Turn code from the current session into a blog post written in the voice
- `make-repo-contribution`: All changes to code must follow the guidance documented in the repository.
- `markdown-to-html`: Convert Markdown files to HTML similar to `marked.js`, `pandoc`, `gomarkdown/markdown`,
- `markdown-to-word-mermaid`: Export Markdown containing Mermaid code fences to Word (.docx) with embedded
- `markstream-install`: Install and configure Markstream streaming Markdown renderers for Vue,
- `mcp-cli`: Interface for MCP (Model Context Protocol) servers via CLI. Use when
- `mcp-copilot-studio-server-generator`: Generate a complete MCP server implementation optimized for Copilot Studio
- `mcp-create-adaptive-cards`: Skill converted from mcp-create-adaptive-cards.prompt.md
- `mcp-create-declarative-agent`: Skill converted from mcp-create-declarative-agent.prompt.md
- `mcp-deploy-manage-agents`: Skill converted from mcp-deploy-manage-agents.prompt.md
- `mcp-implementation-security-review`: Review the implementation source code of MCP (Model Context Protocol)\ \ servers, clients, and tool handlers against a security baseline \u2014 authentication,\ \ sessions, rate limiting, input-schema validation, official-SDK usage, RCE vectors,\ \ and the OWASP MCP Top 10 \u2...
- `mcp-release-qa`: Verify an MCP server before release by exercising a real protocol session,
- `mcp-security-audit`: Audit MCP (Model Context Protocol) server configurations for security issues. Use this skill when: - Reviewing .mcp.json files for security risks - Checking MCP server args for hardcoded secrets or shell injection patterns - Validating that MCP package-runner dependencies use ...
- `md-to-docx`: Convert Markdown files to professionally formatted Word (.docx) documents\ \ with embedded PNG images \u2014 pure JavaScript, no external tools required
- `meeting-minutes`: Generate concise, actionable meeting minutes for internal meetings. Includes
- `memory-merger`: Merges mature lessons from a domain memory file into its instruction file. Syntax: `/memory-merger >domain [scope]` where scope is `global` (default), `user`, `workspace`, or `ws`.
- `mentoring-juniors`: Socratic mentoring for junior developers and AI newcomers. Guides through questions, never answers. Triggers: "help me understand", "explain this code", "I''m stuck", "Im stuck", "I''m confused", "Im confused", "I don''t understand", "I dont understand", "can you teach me", "t...
- `microsoft-agent-framework`: Create, update, refactor, explain, or review Microsoft Agent Framework
- `microsoft-code-reference`: Look up Microsoft API references, find working code samples, and verify\ \ SDK code is correct. Use when working with Azure SDKs, .NET libraries, or Microsoft\ \ APIs\u2014to find the right method, check parameters, get working examples, or\ \ troubleshoot errors. Catches hall...
- `microsoft-docs`: Query official Microsoft documentation to find concepts, tutorials, and
- `microsoft-skill-creator`: Create agent skills for Microsoft technologies using Learn MCP tools.
- `microsoft-store-publisher`: Prepare, validate, submit, and monitor Windows desktop apps in Microsoft
- `migrating-oracle-to-postgres-data-access-code`: Migrates .NET/C# data access code from Oracle to PostgreSQL (Npgsql).
- `migrating-oracle-to-postgres-stored-procedures`: Migrates Oracle PL/SQL stored procedures to PostgreSQL PL/pgSQL. Translates
- `minecraft-plugin-development`: Use this skill when building or modifying Minecraft server plugins for
- `mini-context-graph`: A persistent, compounding knowledge base combining Karpathy's LLM Wiki\ \ pattern\nwith a structured knowledge graph. Ingest documents once \u2014 the LLM\ \ writes wiki\npages, extracts entities/relations into the graph, and stores raw\ \ content for\nevidence retrieval. Know...
- `mkdocs-translations`: Generate a language translation for a mkdocs documentation stack.
- `msgraph-sdk`: Integrate Microsoft Graph SDK into any project \u2014 .NET, TypeScript/JavaScript,\ \ or Python. Covers auth patterns (client credentials, OBO, managed identity), SDK\ \ setup, calling Graph APIs, batching, delta queries, change notifications, throttling,\ \ and permission sco...
- `msstore-cli`: Microsoft Store Developer CLI (msstore) for publishing Windows applications
- `multi-stage-dockerfile`: Create optimized multi-stage Dockerfiles for any language or framework
- `mvvm-toolkit`: CommunityToolkit.Mvvm (the MVVM Toolkit) core: source generators ([ObservableProperty], [RelayCommand], [NotifyPropertyChangedFor], [NotifyCanExecuteChangedFor], [NotifyDataErrorInfo]), base classes (ObservableObject / ObservableValidator / ObservableRecipient), commands (Rela...
- `mvvm-toolkit-di`: Wire CommunityToolkit.Mvvm ViewModels into Microsoft.Extensions.DependencyInjection.
- `mvvm-toolkit-messenger`: CommunityToolkit.Mvvm Messenger pub/sub for decoupled communication between
- `namecheap`: Manage DNS records for domains registered with Namecheap via their API.
- `nano-banana-pro-openrouter`: Generate or edit images via OpenRouter with the Gemini 3 Pro Image model.
- `napkin`: Visual whiteboard collaboration for Copilot CLI. Creates an interactive\ \ whiteboard that opens in your browser \u2014 draw, sketch, add sticky notes, then\ \ share everything back with Copilot. Copilot sees your drawings and text, and responds\ \ with analysis, suggestions, ...
- `next-intl-add-language`: Add new language to a Next.js + next-intl application
- `noob-mode`: Plain-English translation layer for non-technical Copilot CLI users.
- `npm-trusted-publishing`: Set up or fix npm trusted publishing (OIDC) in GitHub Actions and remove
- `nuget-manager`: Manage NuGet packages in .NET projects/solutions. Use this skill when
- `onboard-context-matic`: Interactive onboarding tour for the context-matic MCP server. Walks the user through what the server does, shows all available APIs, lets them pick one to explore, explains it in their project language, demonstrates model_search and endpoint_search live, and ends with a menu o...
- `oo-component-documentation`: Create or update standardized object-oriented component documentation
- `openapi-to-application-code`: Generate a complete, production-ready application from an OpenAPI specification
- `openapi-to-application-java-spring-boot`: Generate a Spring Boot (Java) application from an OpenAPI 3 specification using the spec-first approach: openapi-generator (Maven or Gradle) produces API interfaces and DTOs, you implement controllers, services, persistence, security and tests. Use when asked to build, scaffol...
- `optimize-simplicite-logs`: capability to parse Simplicit\xE9 logs from a raw `.txt` file, filter\ \ fields to reduce noise, and output the result as structured JSON.
- `pdftk-server`: Skill for using the command-line tool pdftk (PDFtk Server) for working
- `penpot-uiux-design`: Comprehensive guide for creating professional UI/UX designs in Penpot using MCP tools. Use this skill when: (1) Creating new UI/UX designs for web, mobile, or desktop applications, (2) Building design systems with components and tokens, (3) Designing dashboards, forms, navigat...
- `performance-review-writer`: Draft performance reviews, self-assessments, peer reviews, and upward feedback in your own voice. Analyzes your contributions, emails, and meeting history via WorkIQ, then produces honest, impact-focused drafts using the STAR format. USE FOR: write my performance review, draft...
- `pester-migration`: Pester migration skill for upgrading PowerShell Pester test suites across\ \ major versions \u2014 v3\u2192v4, v4\u2192v5, and v5\u2192v6. Covers the Discovery/Run\ \ two-phase model, moving setup into BeforeAll, $PSScriptRoot vs $MyInvocation,\ \ mock changes (Assert-MockCall...
- `pester-should-migration`: Experimental (preview) Pester skill for migrating classic Should -Be
- `phoenix-cli`: Debug LLM applications using the Phoenix CLI. Fetch traces, analyze\ \ errors, structure trace review with open coding and axial coding, inspect datasets,\ \ review experiments, query annotation configs, and use the GraphQL API. Use whenever\ \ the user is analyzing traces or ...
- `phoenix-evals`: Build and run evaluators for AI/LLM applications using Phoenix.
- `phoenix-tracing`: OpenInference semantic conventions and instrumentation for Phoenix AI
- `php-mcp-server-generator`: Generate a complete PHP Model Context Protocol server project with tools,
- `pinecone-rag`: Build production RAG pipelines and persistent agent memory using Pinecone\ \ as the vector database backend. ALWAYS USE THIS SKILL when the user mentions Pinecone,\ \ wants to index documents for semantic search, build a retrieval-augmented generation\ \ system, store agent me...
- `planning-oracle-to-postgres-migration-integration-testing`: Creates an integration testing plan for .NET data access artifacts during
- `plantuml-ascii`: Generate ASCII art diagrams using PlantUML text mode. Use when user asks to create ASCII diagrams, text-based diagrams, terminal-friendly diagrams, or mentions plantuml ascii, text diagram, ascii art diagram. Supports: Converting PlantUML diagrams to ASCII art, Creating sequen...
- `playwright-automation-fill-in-form`: Automate filling in a form using Playwright MCP
- `playwright-explore-website`: Website exploration for testing using Playwright MCP
- `playwright-generate-test`: Generate a Playwright test based on a scenario using Playwright MCP
- `poka-yoke`: Mistake-proof code so misuse cannot be expressed, rather than warning
- `ponder`: Convergent deliberation loop - repeated grading passes over one subject
- `postgresql-code-review`: PostgreSQL-specific code review assistant focusing on PostgreSQL best
- `postgresql-optimization`: PostgreSQL-specific development assistant focusing on unique PostgreSQL
- `power-apps-code-app-scaffold`: Scaffold a complete Power Apps Code App project with PAC CLI setup, SDK
- `power-bi-dax-optimization`: Comprehensive Power BI DAX formula optimization prompt for improving
- `power-bi-model-design-review`: Comprehensive Power BI data model design review prompt for evaluating
- `power-bi-performance-troubleshooting`: Systematic Power BI performance troubleshooting prompt for identifying,
- `power-bi-report-design-consultation`: Power BI report visualization design prompt for creating effective, user-friendly,
- `power-platform-architect`: Use this skill when the user needs to transform business requirements,
- `power-platform-mcp-connector-suite`: Generate complete Power Platform custom connector with MCP integration
- `powerbi-modeling`: Power BI semantic modeling assistant for building optimized data models.
- `pr-address-feedback`: Walk through PR review comments one-by-one, deciding for each whether
- `pr-artifact-explorer`: Open, share, and inspect GitHub PRs, issues, workflow runs (including
- `pr-dashboard`: Open a GitHub PR dashboard in the browser. Use when the user asks to
- `pr-screenshots`: Embed before/after screenshots and annotated images in pull request descriptions.
- `prd`: Generate high-quality Product Requirements Documents (PRDs) for software
- `premium-frontend-ui`: A comprehensive guide for GitHub Copilot to craft immersive, high-performance
- `project-workflow-analysis-blueprint-generator`: Comprehensive technology-agnostic prompt generator for documenting end-to-end
- `prompt-optimizer`: Turn any rough prompt, half-formed idea, or task description into a\ \ finished, ready-to-send prompt optimized for any LLM model inside a chat interface\ \ \u2014 NOT the API. Use this skill whenever the user wants to write, rewrite,\ \ optimize, improve, sharpen, or polish a...
- `protobuf-grpc-api-review`: Review Protocol Buffer (.proto) and gRPC API changes for wire and JSON
- `publish-to-pages`: Publish presentations and web content to GitHub Pages. Converts PPTX,
- `pytest-coverage`: Run pytest tests with coverage, discover lines missing coverage, and
- `python-azure-iot-edge-modules`: Build and operate Python Azure IoT Edge modules with robust messaging,
- `python-mcp-server-generator`: Use this skill when the user wants to create a new Model Context Protocol
- `python-pypi-package-builder`: End-to-end skill for building, testing, linting, versioning, and publishing a production-grade Python library to PyPI. Covers all four build backends (setuptools+setuptools_scm, hatchling, flit, poetry), PEP 440 versioning, semantic versioning, dynamic git-tag versioning, OOP/...
- `qdrant-clients-sdk`: Qdrant provides client SDKs for various programming languages, allowing
- `qdrant-deployment-options`: Guides Qdrant deployment selection. Use when someone asks 'how to deploy
- `qdrant-model-migration`: Guides embedding model migration in Qdrant without downtime. Use when
- `qdrant-monitoring`: Guides Qdrant monitoring and observability setup. Use when someone asks
- `qdrant-performance-optimization`: Different techniques to optimize the performance of Qdrant, including
- `qdrant-scaling`: Guides Qdrant scaling decisions. Use when someone asks 'how many nodes
- `qdrant-search-quality`: Diagnoses and improves Qdrant search relevance. Use when someone reports
- `qdrant-version-upgrade`: Guidance on how to upgrade your Qdrant version without interrupting the
- `quality-playbook`: Run a complete quality engineering audit on any codebase. Derives behavioral
- `quarkus-application-development`: Write Quarkus application code: REST with Quarkus REST, validation, exception mappers, OpenAPI, configuration, CDI (ArC), Hibernate ORM with Panache, Mutiny and virtual threads, Reactive Messaging with Kafka, OIDC security, health, metrics, OpenTelemetry, fault tolerance, REST...
- `quarkus-dev-services-and-testing`: Quarkus Dev Services and testing: zero-config containers, @QuarkusTest, @QuarkusIntegrationTest, test resources, RestAssured, @InjectMock, profiles and continuous testing. Use when writing or fixing tests in a Quarkus project.
- `quarkus-native-and-container`: Build Quarkus native executables (Mandrel/GraalVM), fix native failures
- `quasi-coder`: Expert 10x engineer skill for interpreting and implementing code from
- `react-audit-grep-patterns`: Provides the complete, verified grep scan command library for auditing
- `react-container-presentation-component`: Create a React component using the Container/Presentation pattern in
- `react18-batching-patterns`: Provides exact patterns for diagnosing and fixing automatic batching
- `react18-dep-compatibility`: React 18.3.1 and React 19 dependency compatibility matrix.
- `react18-enzyme-to-rtl`: Provides exact Enzyme \u2192 React Testing Library migration patterns\ \ for React 18 upgrades. Use this skill whenever Enzyme tests need to be rewritten\ \ - shallow, mount, wrapper.find(), wrapper.simulate(), wrapper.prop(), wrapper.state(),\ \ wrapper.instance(), Enzyme con...
- `react18-legacy-context`: Provides the complete migration pattern for React legacy context API
- `react18-lifecycle-patterns`: Provides exact before/after migration patterns for the three unsafe class
- `react18-string-refs`: Provides exact migration patterns for React string refs (ref="name" +
- `react19-concurrent-patterns`: Preserve React 18 concurrent patterns and adopt React 19 APIs (useTransition,
- `react19-source-patterns`: Reference for React 19 source-file migration patterns, including API
- `react19-test-patterns`: Provides before/after patterns for migrating test files to React 19 compatibility,
- `readme-blueprint-generator`: Intelligent README.md generation prompt that analyzes project documentation
- `rebase-current-branch`: Rebase the currently checked out feature branch onto the latest upstream
- `refactor`: Surgical code refactoring to improve maintainability without changing
- `refactor-method-complexity-reduce`: Refactor given method `${input:methodName}` to reduce its cognitive complexity
- `refactor-plan`: Create a concrete plan before starting a multi-file refactor. Use when
- `remember`: Transforms lessons learned into domain-organized memory instructions (global or workspace). Syntax: `/remember [>domain [scope]] lesson clue` where scope is `global` (default), `user`, `workspace`, or `ws`.
- `remember-interactive-programming`: A micro-prompt that reminds the agent that it is an interactive programmer.
- `repo-standardizer`: Polish any GitHub repository's surface \u2014 labels (emoji rating tiers,\ \ P0\u2013P3 priority, impact severity), issue forms, PR template, CI workflows,\ \ CODEOWNERS, rulesets, docs. Repo meta & config only \u2014 no code logic touched.\ \ Use when creating a new repo or p...
- `repo-story-time`: Generate a comprehensive repository summary and narrative story from
- `resemble-detect`: Deepfake detection and media safety \u2014 detect AI-generated audio,\ \ images, video, and text, trace synthesis sources, apply watermarks, verify speaker\ \ identity, and analyze media intelligence using Resemble AI
- `resx-source-generator-migration`: Migrates a project that uses checked-in .designer.cs files behind .resx
- `review-and-refactor`: Review and refactor code in your project according to defined instructions
- `reviewing-oracle-to-postgres-migration`: Identifies Oracle-to-PostgreSQL migration risks by cross-referencing
- `rhino3d-scripts`: Authoring and debugging scripts for Rhinoceros 3D (Rhino 8 and later).
- `roslyn-analyzers`: Build, review, debug, package, and test Roslyn diagnostic analyzers,
- `roundup`: Generate personalized status briefings on demand. Pulls from your configured
- `roundup-setup`: Interactive onboarding that learns your communication style, audiences,
- `ruby-mcp-server-generator`: Generate a complete Model Context Protocol server project in Ruby using
- `ruff-recursive-fix`: Run Ruff checks with optional scope and rule overrides, apply safe and
- `rust-mcp-server-generator`: Generate a complete Rust Model Context Protocol server project with tools,
- `salesforce-apex-quality`: Apex code quality guardrails for Salesforce development. Enforces bulk-safety
- `salesforce-component-standards`: Quality standards for Salesforce Lightning Web Components (LWC), Aura
- `salesforce-flow-design`: Salesforce Flow architecture decisions, flow type selection, bulk safety
- `sandbox-npm-install`: Install npm packages in a Docker sandbox environment. Use this skill
- `scaffolding-oracle-to-postgres-migration-test-project`: Scaffolds an xUnit integration test project targeting Oracle in .NET\ \ solutions. Creates the test project, transaction-rollback base class, and seed\ \ data manager. Use only during Phase 3, before writing Oracle baseline integration\ \ tests. Do not invoke during Phase 6 \u...
- `scoutqa-test`: This skill should be used when the user asks to "test this website",
- `screen-recording`: Create annotated animated GIF demos and screen recordings for pull requests
- `secret-scanning`: Guide for configuring and managing GitHub secret scanning, push protection,
- `security-review`: AI-powered codebase security scanner that reasons about code like a\ \ security researcher \u2014 tracing data flows, understanding component interactions,\ \ and catching vulnerabilities that pattern-matching tools miss. Use this skill\ \ when asked to scan code for security ...
- `semantic-kernel`: Create, update, refactor, explain, or review Semantic Kernel solutions
- `server-side-conversion-tracking`: Set up server-side conversion tracking so purchases are reported accurately
- `setup-my-iq`: Create, set up, or update the personal context portfolio: structured markdown files describing who you are, how you work, your teams, and your tool/ADO configuration. Runs the interview workflow for first-time setup and targeted edits for updates. Trigger this skill when the u...
- `shopify-review-triage`: Use this skill when someone wants public Shopify App Store reviews, low-star
- `shuffle-json-data`: Shuffle repetitive JSON objects safely by validating schema consistency
- `signal-write`: Emit structured agent signals \u2014 hands-up, blocked, done, checkpoint,\ \ partnership. Signals are written as JSON to .signals/ for dashboard consumption\ \ and noted in the journal for persistence.
- `skill-distribution-audit`: Audit a skill collection before release or investigate installer omissions,
- `slang-shader-engineer`: Use when working with Slang shaders, shader modules, HLSL-compatible
- `snowflake-semanticview`: Create, alter, and validate Snowflake semantic views using Snowflake
- `speak-summary`: Convert text, markdown, or a summary produced by another skill into a
- `sponsor-finder`: Find which of a GitHub repository's dependencies are sponsorable via
- `spring-boot-4-migration`: Migrate a Spring Boot 3.x application to Spring Boot 4.0 (Spring Framework
- `spring-boot-testing`: Expert Spring Boot testing specialist that selects the best testing techniques for your situation: test slices, Testcontainers with @ServiceConnection, Failsafe integration tests, MockitoBean, JUnit and AssertJ. Written for Spring Boot 4 with notes for Boot 3.
- `spring-observability`: Add and review observability in Spring Boot 3/4 apps: Actuator exposure and health probes, Micrometer metrics, Observation API, OpenTelemetry tracing and OTLP/Prometheus export, structured logging with correlation ids, and safe use of heapdump/threaddump. Use when instrumentin...
- `spring-security`: Configure, test and review Spring Security 6/7 in Spring Boot 3/4 apps: SecurityFilterChain lambda DSL, method security, OAuth2 resource server with JWT, OIDC login, CSRF/CORS, password encoding, headers, actuator protection, and MockMvc security tests. Use when adding or audi...
- `sql-code-review`: Universal SQL code review assistant that performs comprehensive security,
- `sql-object-impact-analysis`: Before modifying a table, column, stored procedure, view, or trigger\ \ in a legacy codebase, trace every place that references it \u2014 across other\ \ SQL objects (procs, views, triggers) AND application code (C#, Angular/TypeScript,\ \ JS, or any language in the repo) \u20...
- `sql-optimization`: Universal SQL performance optimization assistant for comprehensive query
- `sql-server-table-reconciliation`: Use when: comparing SQL Server tables across instances, data migration validation, ETL verification, row mismatch detection, schema drift, reconciliation report, production vs staging comparison. Uses mssql-python driver with Apache Arrow for fast columnar data transfer and co...
- `ssma-console`: Use when: SSMA console operations \u2014 create project, generate assessment\ \ report, convert schema, migrate data, Oracle to SQL Server migration, schema conversion,\ \ data migration
- `steno-mode`: Shorthand-first response compression that cuts ~40% of response tokens while preserving technical precision and exact literals. Use when the user says "steno mode", "shorthand mode", "compressed responses", "token reduction", "brief structured output", or invokes /steno. Suppo...
- `structured-autonomy-generate`: Structured Autonomy Implementation Generator Prompt
- `structured-autonomy-implement`: Structured Autonomy Implementation Prompt
- `structured-autonomy-plan`: Structured Autonomy Planning Prompt
- `suggest-awesome-github-copilot-agents`: Suggest relevant GitHub Copilot Custom Agents files from the awesome-copilot
- `suggest-awesome-github-copilot-instructions`: Suggest relevant GitHub Copilot instruction files from the awesome-copilot
- `suggest-awesome-github-copilot-skills`: Suggest relevant GitHub Copilot skills from the awesome-copilot repository
- `supabase-rls-policies`: Write, review, and test Supabase Row Level Security (RLS) policies so
- `swift-mcp-server-generator`: Generate a complete Model Context Protocol server project in Swift using
- `system-commandline-cli`: Use this skill when adding, modifying, or reviewing CLI commands in a .NET project built with System.CommandLine. Triggers include: creating a new CLI command, adding options or arguments, wiring command handlers, registering subcommands, building command groups, or any archit...
- `technical-job-search`: Use this skill when a software engineer asks for help with job search tasks: parsing or analyzing a job description, tailoring a CV/resume, writing a cover letter, evaluating a job offer, or drafting a post-interview follow-up email. Do not activate for general career advice u...
- `technology-stack-blueprint-generator`: Comprehensive technology stack blueprint generator that analyzes codebases
- `terraform-azurerm-set-diff-analyzer`: Analyze Terraform plan JSON output for AzureRM Provider to distinguish
- `test-gap-audit`: Run a read-only audit for missing, weak, stale, or mis-scoped test coverage.
- `threat-model-analyst`: Full STRIDE-A threat model analysis and incremental update skill for\ \ repositories and systems. Supports two modes: (1) Single analysis \u2014 full\ \ STRIDE-A threat model of a repository, producing architecture overviews, DFD diagrams,\ \ STRIDE-A analysis, prioritized fin...
- `tiny-stepping`: Incremental development workflow that makes the smallest meaningful change
- `tldr-prompt`: Create tldr summaries for GitHub Copilot files (prompts, agents, instructions,
- `tm7-threat-model`: Creates valid Microsoft Threat Modeling Tool (.tm7) files compatible
- `transloadit-media-processing`: Process media files (video, audio, images, documents) using Transloadit.
- `tugboat`: Anxiety-aware, evidence-driven collaboration for stalled or high-stakes
- `typescript-mcp-server-generator`: Generate a complete MCP server project in TypeScript using the MCP TypeScript
- `typespec-api-operations`: Add GET, POST, PATCH, and DELETE operations to a TypeSpec API plugin
- `typespec-create-agent`: Generate a complete TypeSpec declarative agent with instructions, capabilities,
- `typespec-create-api-plugin`: Generate a TypeSpec API plugin with REST operations, authentication,
- `ui-screenshots`: Capture screenshots of web apps during development using Playwright and
- `unit-test-vue-pinia`: Write and review unit tests for Vue 3 + TypeScript + Vitest + Pinia codebases.
- `update-avm-modules-in-bicep`: Update Azure Verified Modules (AVM) to latest versions in Bicep files.
- `update-implementation-plan`: Update an existing implementation plan file with new or update requirements
- `update-llms`: Update the llms.txt file in the root folder to reflect changes in documentation
- `update-markdown-file-index`: Update a markdown file section with an index/table of files from a specified
- `update-specification`: Update an existing specification file for the solution, optimized for
- `upstash-redis`: Use Redis over HTTP from serverless and edge runtimes with @upstash/redis, and add rate limiting with @upstash/ratelimit. Use when the user mentions Upstash Redis, needs Redis from a Next.js route handler or middleware, Vercel, Cloudflare Workers, Deno, or Bun without TCP conn...
- `v-development`: Guide GitHub Copilot through V language development: installing the toolchain, project layout with v.mod, building, testing, formatting, and writing idiomatic V including Option/Result error handling. Use when the user works with V source files, v.mod projects, or asks about V...
- `vardoger-analyze`: Use when the user asks to personalize the GitHub Copilot CLI assistant, adapt Copilot to their style, use vardoger, or analyze their Copilot CLI conversation history. Reads the local session directory at `~/.copilot/session-state/`, extracts recurring preferences and conventio...
- `vcpkg`: Guide for setting up vcpkg in C++ projects, managing dependency versions,
- `verify-agent-action`: Review a proposed AI-agent action or human-approval packet before execution.\ \ Use when an agent wants to run a consequential tool, command, deployment, message,\ \ purchase, credential operation, or data mutation; when checking whether approval\ \ still matches the exact act...
- `vscode-ext-commands`: Guidelines for contributing commands in VS Code extensions. Indicates
- `vscode-ext-localization`: Guidelines for proper localization of VS Code extensions, following VS
- `web-design-reviewer`: This skill enables visual inspection of websites running locally or remotely
- `webapp-testing`: Toolkit for interacting with and testing local web applications using
- `webmcpify`: WebMCP agent skill for curated core coverage or route-by-route parity\ \ \u2014 inventory an existing web app, integrate approved tools, then inspect,\ \ verify and heal them in a real browser. Use for \"webmcpify\", \"add WebMCP\"\ , or \"expose app actions to AI agents\".
- `what-context-needed`: Ask Copilot what files it needs to see before answering a question
- `winmd-api-search`: Find and explore Windows desktop APIs. Use when building features that\ \ need platform capabilities \u2014 camera, file access, notifications, UI controls,\ \ AI/ML, sensors, networking, etc. Discovers the right API for a task and retrieves\ \ full type details (methods, prop...
- `winui3-migration-guide`: UWP-to-WinUI 3 migration reference. Maps legacy UWP APIs to correct Windows
- `workiq-copilot`: Guides the Copilot CLI on how to use the WorkIQ CLI/MCP server to query
- `workshop-create`: Create a new workshop or use an existing directory as one. Handles two paths: (A) use an existing local directory the operator points at, or (B) create a new private GitHub repo in the signed-in account. Never creates a repo inside another repo.
- `write-coding-standards-from-file`: Write a coding standards document for a project using the coding styles
- `x-twitter-scraper`: Build GitHub Copilot workflows with Xquik X API SDKs, REST endpoints,

## claude-marketplace (55)

- `agent-development`: This skill should be used when the user asks to "create an agent", "add an agent", "write a subagent", "agent frontmatter", "when to use description", "agent examples", "agent tools", "agent colors", "autonomous agent", or needs guidance on agent structure, system prompts, tri...
- `breakdown-diagnosis`: When a machine goes down, reads the sensor window before the failure, the asset's maintenance history including the free-text close-out notes technicians actually wrote, photos of what they can see, and the manufacturer's troubleshooting tree — then ranks likely causes, each w...
- `breakdown-to-next-report`: Runs the chain from a machine going down to the diagnosis landing in tomorrow's production report: reads the sensor window, the maintenance history and its free-text close-out notes, technician photographs and the manufacturer's manual together, ranks likely causes with the ch...
- `build-mcp-app`: This skill should be used when the user wants to build an "MCP app", add "interactive UI" or "widgets" to an MCP server, "render components in chat", build "MCP UI resources", make a tool that shows a "form", "picker", "dashboard" or "confirmation dialog" inline in the convers...
- `build-mcp-server`: This skill should be used when the user asks to "build an MCP server", "create an MCP", "make an MCP integration", "wrap an API for Claude", "expose tools to Claude", "make an MCP app", or discusses building something with the Model Context Protocol. It is the entry point for ...
- `build-mcpb`: This skill should be used when the user wants to "package an MCP server", "bundle an MCP", "make an MCPB", "ship a local MCP server", "distribute a local MCP", discusses ".mcpb files", mentions bundling a Node or Python runtime with their MCP server, or needs an MCP server tha...
- `cardputer-buddy`: Iterate on the Cardputer-Adv MicroPython app bundle (Claude Buddy, Snake, Hello) after the device is already provisioned via m5-onboard. Use when the user wants to add a new app, push a single changed .py without re-flashing, watch device serial logs, or run a one-shot REPL co...
- `claude-automation-recommender`: Analyze a codebase and recommend Claude Code automations (hooks, subagents, skills, plugins, MCP servers). Use when user asks for automation recommendations, wants to optimize their Claude Code setup, mentions improving Claude Code workflows, asks how to first set up Claude Co...
- `claude-for-manufacturing-onboarding`: Sets the plugin up for one plant on first run. Asks which ERP, CAD, CMMS and document system the plant uses and tests the four supported connectors (Microsoft 365, Oracle NetSuite, Infor M3, Autodesk Fusion), takes a bulk drop of the plant's own documents so it asks only what ...
- `claude-md-improver`: Audit and improve CLAUDE.md files in repositories. Use when user asks to check, audit, update, improve, or fix CLAUDE.md files. Scans for all CLAUDE.md files, evaluates quality against templates, outputs quality report, then makes targeted updates. Also use when the user menti...
- `claude-security`: Claude Security: scan the codebase (the whole repository or a scoped part of it), scan changes (this branch's or a pull request's diff, or one commit), or suggest patches (findings turned into targeted patch files, each verified by a panel of agents, that you apply when you ch...
- `climb`: Work out where a teammate, the champion, or a team is on the steps of AI adoption, and what to try next. Use when a champion wants to help someone move up a step.
- `command-development`: This skill should be used when the user asks to "create a slash command", "add a command", "write a custom command", "define command arguments", "use command frontmatter", "organize commands", "create command with file references", "interactive command", "use AskUserQuestion i...
- `custom-connector`: Gets the plugin talking to a manufacturing system that has no vendor MCP, working down a seven-tier access ladder in order — vendor MCP, community MCP, a scoped API wrapper, a read-only database view, a Zapier bridge, screen automation as a last resort, or a scheduled export c...
- `customer-inquiry-intake`: Reads a customer RFQ in whatever shape it arrived — a PDF drawing package, a 40-line spreadsheet, a portal export, a phone photo of a marked-up print, or a forwarded thread where the real requirement is four messages down — and pulls specifications, quantities and dates into o...
- `daily-production-report`: Produces the morning production report: output against plan by line, cell and product; OEE with availability, performance and quality shown separately; the downtime log ranked both by minutes and by frequency; scrap and downtime priced in dollars; week-over-week movers; and th...
- `data-consolidate`: Joins the plant's scheduled exports and connector data into one working dataset — ERP items (NetSuite or Infor M3), sales orders, production work orders, purchase orders, inventory, routings and closed-job operation actuals; CMMS assets and maintenance work orders; and the MES...
- `design-space-explore`: Generates a batch of CAD variants directly in Autodesk Fusion by applying changed parameters to an engineer's existing model, never designing from scratch and never overwriting the base. Checks first whether the parameters the engineer wants to vary actually drive the model's ...
- `discord-access`: Manage Discord channel access — approve pairings, edit allowlists, set DM/group policy. Use when the user asks to pair, approve someone, check who's allowed, or change policy for the Discord channel.
- `discord-configure`: Set up the Discord channel — save the bot token and review access policy. Use when the user pastes a Discord bot token, asks to configure Discord, asks "how do I set this up" or "who can reach me," or wants to check channel status.
- `example-command`: An example user-invoked skill that demonstrates frontmatter options and the skills/<name>/SKILL.md layout
- `example-skill`: This skill should be used when the user asks to "demonstrate skills", "show skill format", "create a skill template", or discusses skill development patterns. Provides a reference template for creating Claude Code plugin skills.
- `faq`: Turn repeat questions into a pinned FAQ. Use when a champion keeps answering the same questions.
- `hackathon`: Plan a hackathon, either from a team's real backlog or as open-ended creative play with Claude Code. Use when a champion wants to run a hack day or a shorter hack session.
- `hook-development`: This skill should be used when the user asks to "create a hook", "add a PreToolUse/PostToolUse/Stop hook", "validate tool use", "implement prompt-based hooks", "use ${CLAUDE_PLUGIN_ROOT}", "set up event-driven automation", "block dangerous commands", or mentions hook events (P...
- `imessage-access`: Manage iMessage channel access — approve pairings, edit allowlists, set DM/group policy. Use when the user asks to pair, approve someone, check who's allowed, or change policy for the iMessage channel.
- `imessage-configure`: Check iMessage channel setup and review access policy. Use when the user asks to configure iMessage, asks "how do I set this up" or "who can reach me," or wants to know why texts aren't reaching the assistant.
- `inspection-to-capa`: Runs the quality chain end to end: writes the nonconformance against the requirement it violates, searches history at the moment of writing to say whether this has happened before and whether the last fix held, reads sensor and inspection data on one verified timeline, propose...
- `m5-onboard`: End-to-end onboarding for a freshly-plugged-in M5Stack ESP32 device (Cardputer, Cardputer-Adv, Core, CoreS3, Stick) — detect on USB, flash UIFlow 2.0 firmware, and install the Claude Buddy MicroPython app bundle. Use whenever the user plugs in or wants to flash/provision/reset...
- `math-olympiad`: (no description)
- `maturity`: Evaluate an organization's AI maturity on the steps of AI adoption and write a polished, shareable HTML report with evidence for each score. Use when a champion wants to know where their org or team stands, or to compare with an earlier report.
- `mcp-integration`: This skill should be used when the user asks to "add MCP server", "integrate MCP", "configure MCP in plugin", "use .mcp.json", "set up Model Context Protocol", "connect external service", mentions "${CLAUDE_PLUGIN_ROOT} with MCP", or discusses MCP server types (SSE, stdio, HTT...
- `morning-plant-pulse`: Runs the overnight chain that has the morning production report waiting before anyone asks for it: joins last night's planning, production and maintenance exports, flags the mismatched keys, then computes output against plan, OEE with its three components, downtime ranked two ...
- `ncr-writeup`: Writes the nonconformance report: what was found and measured, the specific requirement it violates cited to its document and locator, how many parts are actually suspect and why that scope rather than a narrower one, and where every one of them physically is across all five l...
- `office-hours`: Set up and run Claude Code office hours, including the calendar event when the champion's own calendar connector allows it. Use when a champion wants a regular time for teammates to bring problems.
- `patterns`: Find patterns worth sharing from recent PRs and repo history, both repeats to fix and good practices worth spreading. Use when a champion wants to know what the team should reuse or learn from.
- `playground` [Helpful]: Creates interactive HTML playgrounds — self-contained single-file explorers that let users configure something visually through controls, see a live preview, and copy out a prompt. Use when the user asks to make a playground, explorer, or interactive tool for a topic.
- `plugin-settings`: This skill should be used when the user asks about "plugin settings", "store plugin configuration", "user-configurable plugin", ".local.md files", "plugin state files", "read YAML frontmatter", "per-project plugin settings", or wants to make plugin behavior configurable. Docum...
- `plugin-structure`: This skill should be used when the user asks to "create a plugin", "scaffold a plugin", "understand plugin structure", "organize plugin components", "set up plugin.json", "use ${CLAUDE_PLUGIN_ROOT}", "add commands/agents/skills/hooks", "configure auto-discovery", or needs guid...
- `project-artifact`: Generate and publish a project status artifact — an opinionated, tabbed status page for a project too big for one update (overview & success criteria, the workstream sequence, next steps, plus background, plan, risks & open questions, and decisions/FAQ when they earn a tab) — ...
- `quote-build`: Produces the make-to-order quote from the intake form, comparable prior jobs and cost history, with every number traced to where it came from — material at the price actually paid on a named purchase order, machine hours per operation from a labelled ladder (current routing, c...
- `receipts`: Generate a personal Claude Code usage & impact report ("receipts") from this machine's local session transcripts — for justifying Claude Code usage/spend to a manager, self-review, or "what have I been using this for" check-ins. Mines ~/.claude/projects locally (no extra API c...
- `rfq-to-quote`: Runs the whole RFQ-to-quote chain end to end: reads the inquiry and its drawings, checks it against what the plant can build, drafts the questions back, returns a provisional bid/no-bid, pulls cost history, routings and closed-job actuals, builds an internal estimating model i...
- `root-cause-capa`: Reads sensor history, inspection measurements, maintenance records and prior tickets onto one verified timeline, runs the pattern checks in code rather than by eye — SPC drift, clustering by lot, shift, operator, machine and tool change, correlation with a maintenance event — ...
- `routines`: Set up recurring champion routines as Claude Code scheduled tasks. Use when a champion wants work like a weekly patterns digest, a stale guidance check, or a monthly lead update to happen without kicking it off by hand.
- `session-report`: Generate an explorable HTML report of Claude Code session usage (tokens, cache, subagents, skills, expensive prompts) from ~/.claude/projects transcripts.
- `siege`: Work on one hard mathematics problem in rounds: each round a judge writes a few self-contained questions, independent workers answer them, and the judge keeps a ledger of what is proved, refuted and open, until the judge concludes or the rounds run out, and then a proof.md say...
- `skill-development`: This skill should be used when the user wants to "create a skill", "add a skill to plugin", "write a new skill", "improve skill description", "organize skill content", or needs guidance on skill structure, progressive disclosure, or skill development best practices for Claude ...
- `solo`: Work on one hard mathematics problem in this session yourself, with no sub-agents: reason in stages, record each settled step in a notes file so that nothing written is lost if a response is cut off, and end with a self-contained proof.md. Usage: /math-proof:solo <the problem,...
- `supplier-escape-to-alternate-source`: Runs the cross-area chain from a nonconformance traced to purchased material through to an alternate-source RFQ: writes the NCR and its containment, establishes root cause against the supplier rather than the process, records the corrective action, then builds the sourcing pac...
- `supplier-quote-request`: Builds the RFQ package that goes out to suppliers — drawing and specification at the verified current revision, the demand picture, the quality clause list, commercial terms, and a mandated response format that makes the returned bids comparable by construction. Lists everythi...
- `telegram-access`: Manage Telegram channel access — approve pairings, edit allowlists, set DM/group policy. Use when the user asks to pair, approve someone, check who's allowed, or change policy for the Telegram channel.
- `telegram-configure`: Set up the Telegram channel — save the bot token and review access policy. Use when the user pastes a Telegram bot token, asks to configure Telegram, asks "how do I set this up" or "who can reach me," or wants to check channel status.
- `trade-study-report`: Turns a filled-in trade study matrix and its analysis results into a scored comparison and a decision memo, with every score cited to its source. Runs the sensitivity analysis every time — where the winner flips, which criterion the decision actually rests on, whether an optio...
- `writing-rules`: This skill should be used when the user asks to "create a hookify rule", "write a hook rule", "configure hookify", "add a hookify rule", or needs guidance on hookify rule syntax and patterns.

## creative (40)

- `ai-presenter-video`: Make a verified AI presenter video from script + image.
- `anatomy`: Explain an idea as an interactive isometric machine figure.
- `archify`: Validated interactive HTML diagrams, upstream-maintained.
- `architecture-diagram`: Dark-themed SVG architecture/cloud/infra diagrams as HTML.
- `ascii-art`: ASCII art: pyfiglet, cowsay, boxes, image-to-ascii.
- `ascii-video`: ASCII video: convert video/audio to colored ASCII MP4/GIF.
- `auteur`: Design and build cinematic, award-level web pages.
- `baoyu-article-illustrator`: Article illustrations: type × style × palette consistency.
- `baoyu-comic`: Knowledge comics (知识漫画): educational, biography, tutorial.
- `baoyu-infographic`: Infographics: 21 layouts x 21 styles (信息图, 可视化).
- `brag`: Project launch video via Hyperframes, upstream-maintained.
- `brag-slim`: Launch video from a project or URL, upstream-maintained.
- `claude-design` [Required]: Design one-off HTML artifacts (landing, deck, prototype).
- `comfyui`: Generate images, video, and audio via diffusion workflows.
- `concept-diagrams`: Generate flat, minimal educational SVG visuals as HTML.
- `creative-ideation`: Generate ideas via named methods from creative practice.
- `design-md` [Helpful]: Author/validate/export Google's DESIGN.md token spec files.
- `draw-your-font`: Turn a handwriting photo into an installable TTF font.
- `dream-loop`: Build stunning 3D scenes via a concept-art fidelity loop.
- `excalidraw`: Hand-drawn Excalidraw JSON diagrams (arch, flow, seq).
- `heartmula`: HeartMuLa: Suno-like song generation from lyrics + tags.
- `humanizer`: Humanize text: strip AI-isms and add real voice.
- `hyperframes`: Render MP4/WebM videos from HTML compositions.
- `impeccable`: Frontend design guidance, upstream-maintained (impeccable).
- `ip-as-logo` [Required]: Design minimal cute IP mascot marks readable at 32px.
- `kanban-video-orchestrator`: Plan and run multi-agent video production pipelines.
- `manim-video`: Manim CE animations: 3Blue1Brown math/algo videos.
- `meme-generation`: Create meme PNGs from templates with Pillow text overlay.
- `mono-color`: Generate one- or two-ink editorial print poster images.
- `p5js`: p5.js sketches: gen art, shaders, interactive, 3D.
- `pixel-art`: Pixel art w/ era palettes (NES, Game Boy, PICO-8).
- `popular-web-designs` [Helpful]: 54 real design systems (Stripe, Linear, Vercel) as HTML/CSS.
- `pretext`: Build creative browser demos with DOM-free text layout.
- `simple-english`: Rewrite text to ASD-STE100 Simplified Technical English.
- `sketch`: Throwaway HTML mockups: 2-3 design variants to compare.
- `social-media-content-calendar`: Plan multi-platform social campaigns: briefs to posting.
- `songwriting-and-ai-music`: Songwriting craft and Suno AI music prompts.
- `system-atlas`: Build explorable isometric architecture atlases as HTML.
- `tldraw-offline`: Drive and script tldraw offline canvases with an agent.
- `unreal-mcp`: Automate Unreal Engine editor scenes, actors, and renders.

## productivity (19)

- `box`: Box manages cloud files, sharing, search, and metadata.
- `canvas`: Fetch Canvas LMS courses and assignments via API token.
- `decision-questionnaire`: Turn an unanswerable decision into a questionnaire doc.
- `document-to-action-items`: Extract cited obligations, deadlines, tasks from documents.
- `google-workspace`: Gmail, Calendar, Drive, Docs, Sheets via gws CLI or Python.
- `here-now`: Publish sites to {slug}.here.now and store files in Drives.
- `live-dashboard`: Build self-updating dashboards from live sources.
- `maps`: Geocode, POIs, routes, timezones via OpenStreetMap/OSRM.
- `meeting-action-items`: Turn meeting notes into cited decisions, owners, tickets.
- `memento-flashcards`: Spaced-repetition flashcards: create, review, quiz, export.
- `microsoft-office`: Create, read, and edit Word, PowerPoint, and Excel files.
- `pdf`: PDF files: create, read, merge, fill, OCR, edit text.
- `product-price-monitor`: Watch product, flight, or listing prices; alert on target.
- `property-listings`: Present property and rental listings as desktop cards.
- `shop`: Shop catalog search, checkout, order tracking, returns.
- `siyuan`: Query and edit a SiYuan knowledge base via its API.
- `teams-meeting-pipeline`: Teams meeting summaries, job replay, Graph subscriptions.
- `telephony`: Provision Twilio numbers, SMS/MMS, and AI outbound calls.
- `weekly-review-planning`: Weekly reset: commitments, stalled work, next-week plan.

## local_repo (18)

- `brainstorming`: You MUST use this before any creative or build work: creating features, building components, adding functionality, modifying behavior, or planning anything new, in software or out of it (a website, a talk, a business). Finds out what the user actually wants and why, one questi...
- `clean-code`: Pragmatic coding standards - concise, direct, no over-engineering, no
- `code-reviewer`: You MUST use this when asked to review code: a pull request, a branch, a commit, staged or uncommitted changes, or "check this before I merge". Scopes the review to the diff, reads the surrounding code, hunts for real bugs (correctness, security, data loss, concurrency, broken...
- `file-organizer`: Intelligently organizes files and folders by understanding context, finding
- `frontend-design` [Helpful]: Guidance for distinctive, intentional visual design when building new
- `git-commit-helper`: Generate descriptive commit messages by analyzing git diffs. Use when
- `gitlab-duo-trial`: Route project-level tasks through the active GitLab Duo Trial MCP server.
- `mcp-builder`: Guide for creating high-quality MCP (Model Context Protocol) servers
- `mobile-design` [Required]: Mobile-first design thinking and decision-making for iOS and Android
- `react-best-practices`: React and Next.js performance optimization guidelines from Vercel Engineering.
- `senior-architect`: Comprehensive software architecture skill for designing scalable, maintainable
- `senior-backend`: Comprehensive backend development skill for building scalable backend
- `senior-frontend`: You MUST use this whenever you build, change or review user interface code, including small UI tweaks and when the user is in a hurry: pages, components, forms, lists, tables, modals, navigation, layout or styling in React, Next.js, Vue, Svelte, Astro or plain HTML/CSS/Tailwin...
- `senior-fullstack`: Comprehensive fullstack development skill for building complete web applications
- `senior-prompt-engineer`: World-class prompt engineering skill for LLM optimization, prompt patterns,
- `senior-security`: Comprehensive security engineering skill for application security, penetration
- `ui-design-system` [Required]: UI design system toolkit for Senior UI Designer including design token
- `ui-ux-pro-max` [Helpful]: UI/UX design intelligence. 50 styles, 21 palettes, 50 font pairings, 20 charts, 9 stacks (React, Next.js, Vue, Svelte, SwiftUI, React Native, Flutter, Tailwind, shadcn/ui). Actions: plan, build, create, design, implement, review, fix, improve, optimize, enhance, refactor, chec...

## software-development (18)

- `ast-grep`: AST-aware structural code search and rewrite via ast-grep.
- `code-wiki`: Generate wiki docs + Mermaid diagrams for any codebase.
- `codebase-inspection`: Inspect codebases w/ pygount: LOC, languages, ratios.
- `dogfood`: Exploratory QA of web apps: find bugs, evidence, reports.
- `github`: GitHub via gh CLI: PRs, issues, reviews, repos, auth.
- `grill-me`: Adversarial plan interview before implementation.
- `hermes-agent-skill-authoring`: Author in-repo SKILL.md files: frontmatter and structure.
- `inspecting-hermes-desktop-dom`: Read the live Hermes desktop DOM/CSS over CDP.
- `node-inspect-debugger`: Debug Node.js via --inspect + Chrome DevTools Protocol CLI.
- `pr-lens`: Draw code changes as animated architecture/data-flow SVGs.
- `python-debugpy`: Debug Python: pdb REPL + debugpy remote (DAP).
- `requesting-code-review`: Pre-commit review: security scan, quality gates, auto-fix.
- `rest-graphql-debug`: Debug REST/GraphQL APIs: status codes, auth, schemas, repro.
- `simplify-code`: Parallel 4-agent cleanup of recent code changes.
- `spike`: Throwaway experiments to validate an idea before build.
- `subagent-driven-development`: Execute plans via delegate_task subagents (2-stage review).
- `systematic-debugging`: 4-phase root cause debugging: understand bugs before fixing.
- `test-driven-development`: TDD: enforce RED-GREEN-REFACTOR, tests before code.

## research (17)

- `arxiv`: Search arXiv papers by keyword, author, category, or ID.
- `bioinformatics`: Gateway to 400+ genomics and computational biology skills.
- `blogwatcher`: Monitor blogs and RSS/Atom feeds via blogwatcher-cli tool.
- `competitor-news-monitor`: Watch named companies for material news; cited digests.
- `darwinian-evolver`: Evolve prompts/regex/SQL/code with Imbue's evolution loop.
- `domain-intel`: Passive recon of subdomains, SSL certs, WHOIS, and DNS.
- `drug-discovery`: Drug discovery: ChEMBL search, drug-likeness, interactions.
- `dspy`: DSPy: declarative LM programs, auto-optimize prompts, RAG.
- `gitnexus-explorer`: Serve an interactive codebase knowledge graph web UI.
- `grounded-citations`: Ground answers and documents in cited, verifiable sources.
- `llm-wiki`: Karpathy's LLM Wiki: build/query interlinked markdown KB.
- `osint-investigation`: Follow the money via public records and sanctions data.
- `parallel-cli`: Agent-native web search, deep research, and enrichment.
- `qmd`: Hybrid local search over notes, docs, and transcripts.
- `research-paper-writing`: Write ML papers for NeurIPS/ICML/ICLR: design→submit.
- `rss-feeds`: Read RSS, Atom, JSON feeds; discover feeds behind a page.
- `scrapling`: Scrape sites with stealth browsing and Cloudflare bypass.

## mlops (16)

- `accelerate`: Run PyTorch training across GPUs with minimal changes.
- `chroma`: Embedding database for RAG and semantic search.
- `faiss`: Fast vector similarity search at billion scale.
- `flash-attention`: Speed up long-sequence transformer training and inference.
- `lambda-labs`: On-demand GPU cloud instances for ML training.
- `modal`: Serverless GPU cloud for ML jobs and model APIs.
- `nemo-curator`: Curate LLM training data: dedupe, filter, PII redaction.
- `obliteratus` **DO NOT INVOKE**: OBLITERATUS: abliterate LLM refusals (diff-in-means).
- `peft`: Fine-tune large LLMs with LoRA on limited GPU memory.
- `pytorch-fsdp`: Fully sharded data-parallel training for large models.
- `pytorch-lightning`: Clean training loops with built-in distributed support.
- `saelens`: Train sparse autoencoders to interpret model features.
- `simpo`: Reference-free preference alignment, simpler than DPO.
- `slime`: RL post-training for LLMs with Megatron and SGLang.
- `tensorrt-llm`: High-throughput LLM inference on NVIDIA GPUs.
- `torchtitan`: Pretrain LLMs at scale with PyTorch 4D parallelism.

## root (16)

- `harbor`: Manage downloads in the Harbor macOS app. Use when the user asks to download files, media, or torrents; inspect progress; pause or resume transfers; manage tags, bandwidth, and torrent files; or change Harbor settings.
- `imagegen`: Generate or edit raster images when the task benefits from AI-created bitmap visuals such as photos, illustrations, textures, sprites, mockups, or transparent-background cutouts. Use when Codex should create a brand-new image, transform an existing image, or derive visual vari...
- `lpm`: Shortcut that loads the two lpm skills — `lpm-cli` (control projects: start/stop services, logs, agent status, create and run automations, duplicate into standalone copies or create Git worktrees) and `lpm-config` (create/edit project YAML configs). Use when the user types /lp...
- `lpm-cli`: Operate lpm-managed projects through the `lpm` CLI: start or stop projects and services, inspect logs and agent status, wait for readiness, run actions, create, edit, run, pause, and read scheduled automations, manage `/name` skills made in lpm, and duplicate projects into sta...
- `lpm-config`: Create and edit lpm YAML configs for projects, duplicates, worktree metadata, services, actions, header and footer button zones and zone layers, terminals, profiles, SSH projects, and shared config layers. Use when the user explicitly asks to configure lpm, add an lpm service/...
- `lpm-memory`: Shared project memory for AI coding agents: save or recall work-session logs in `~/.lpm/memory/<project>/<session>.md` so another agent CLI (Claude Code, Codex, Gemini) or a future session can continue the work by session name. Invoke with a session id (e.g. `/lpm-memory auth-...
- `openai-docs`: API first-timers, Codex/Work Q&A. If the user already has an OpenAI API integration, skip this skill for API questions and use the developer docs. Read this skill before answering how Codex or ChatGPT Work behaves, where to find a feature, or how to configure or troubleshoot t...
- `paseo`: Paseo reference for managing hosts, projects, workspaces, workspace scripts, agents, schedules, and heartbeats.
- `paseo-advisor`: Spin up a single agent as an advisor — second opinion on the current task. Use when the user says "advisor", "second opinion", "what does X think", or wants an outside take without delegating the work itself.
- `paseo-committee`: Form a committee of two high-reasoning agents to step back, do root cause analysis, and produce a plan. Use when stuck, looping, tunnel-visioning, or facing a hard planning problem.
- `paseo-handoff`: Hand off the current task to another agent with full context. Use when the user says "handoff", "hand off", "hand this to", or wants to pass work to another agent.
- `paseo-help`: Answer questions about the Paseo product and app, including setup, configuration, connectivity, providers, workspaces, updates, logs, and troubleshooting. Use when a user inside Paseo asks how Paseo works, how to configure it, or why something is broken; use the paseo skill in...
- `paseo-plugin`: Build and manage trusted local Paseo plugins. Use when the user asks to create, edit, install, reload, enable, disable, remove, or troubleshoot a Paseo plugin; add lifecycle hooks; transform agent configuration, environment, MCP servers, or workspace creation; automate permiss...
- `review-agent`: Perform a read-only, defect-first review of a specified code change and return every actionable finding. Use when another agent delegates review of uncommitted changes, a base-branch diff, a commit, or custom review instructions.
- `skill-creator`: Create or update a Codex skill with appropriately scoped instructions and any needed supporting resources.
- `skill-installer`: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a curated skill, or install a skill from another repo (including private repos).

## autonomous-ai-agents (11)

- `agent-merge-conflict-arbiter`: Neutral arbiter for merge conflicts between two agents.
- `antigravity-cli`: Operate the Antigravity CLI (agy): plugins, auth, sandbox.
- `blackbox`: Delegate coding tasks to the Blackbox AI multi-model CLI.
- `claude-code`: Delegate coding to Claude Code CLI (features, PRs).
- `codex`: Delegate coding to OpenAI Codex CLI (features, PRs).
- `computer-use`: Drive the desktop background-first; escalate on signal.
- `dynamic-workflow`: Plan-in-code fan-outs, adversarial verification, waves.
- `grok`: Delegate coding to xAI Grok Build CLI (features, PRs).
- `hermes-agent`: Use, configure, theme, extend, and orchestrate Hermes Agent.
- `opencode-cli`: Delegate coding to OpenCode CLI (features, PR review).
- `openhands`: Delegate coding to OpenHands CLI (model-agnostic, LiteLLM).

## finance (9)

- `3-statement-model`: Build integrated IS/BS/CF financial workbooks in Excel.
- `comps-analysis`: Build comparable-company valuation workbooks in Excel.
- `dcf-model`: Build discounted cash flow valuation workbooks in Excel.
- `excel-author`: Build auditable financial workbooks headless via openpyxl.
- `lbo-model`: Build leveraged buyout workbooks with IRR/MOIC in Excel.
- `merger-model`: Build M&A accretion/dilution workbooks in Excel.
- `polymarket`: Query Polymarket: markets, prices, orderbooks, history.
- `pptx-author`: Build PowerPoint decks headless with python-pptx.
- `stocks`: Stock quotes, history, search, compare, crypto via Yahoo.

## devops (8)

- `actual-setup`: Set up Actual Computer (actual.inc) inference in Hermes.
- `docker-management`: Manage Docker containers, images, volumes, and Compose.
- `hermes-s6-container-supervision`: Modify or debug s6 services in the Hermes Docker image.
- `inference-sh-cli`: Run 150+ AI apps (image, video, LLM) via inference.sh CLI.
- `pinggy-tunnel`: Zero-install localhost tunnels over SSH via Pinggy.
- `sdlc-review`: Review Kanban handoffs and route verified outcomes.
- `setup-wizard-generator`: Generate a bash wizard guiding a human through manual setup.
- `watchers`: Poll RSS, JSON APIs, and GitHub with watermark dedup.

## security (6)

- `1password`: Set up op CLI, sign in, and read or inject secrets.
- `godmode` **DO NOT INVOKE**: Jailbreak LLMs: Parseltongue, GODMODE, ULTRAPLINIAN.
- `oss-forensics`: GitHub supply-chain forensics: recovery, IOCs, reporting.
- `sherlock`: Find accounts for a username across 400+ platforms.
- `unbroker`: Remove your info from data-broker sites, by name or phone.
- `web-pentest`: Authorized web pentest: recon, proof-based exploits, report.

## web-development (5)

- `cloudflare-temporary-deploy`: Deploy a Worker live, no account, via wrangler --temporary.
- `har-derived-api-client`: Record a site's XHR into a HAR, derive an HTTP client.
- `page-agent`: Embed an in-page natural-language GUI copilot in web apps.
- `publish-site`: Versioned site deploys to GitHub/Cloudflare/Netlify Pages.
- `scrollcraft`: Premium scroll-driven landing pages; scroll = timeline.

## apple (4)

- `apple-notes`: Manage Apple Notes via memo CLI: create, search, edit.
- `apple-reminders`: Apple Reminders via remindctl: add, list, complete.
- `findmy`: Track Apple devices/AirTags via FindMy.app on macOS.
- `imessage`: Send and receive iMessages/SMS via the imsg CLI on macOS.

## blockchain (3)

- `evm`: Read-only EVM client: wallets, tokens, gas across 8 chains.
- `hyperliquid`: Hyperliquid market data, account history, trade review.
- `solana`: Query Solana wallets, tokens, txs, and NFTs in USD.

## email (3)

- `agentmail`: Use when an agent needs AgentMail CLI email inboxes.
- `email-inbox-triage`: Triage an inbox: prioritize threads, draft replies safely.
- `himalaya`: Himalaya CLI: IMAP/SMTP email from terminal.

## mcp (3)

- `fastmcp`: Build, test, and deploy Python MCP servers.
- `mcp-oauth-remote-gateway`: Manual OAuth for remote MCP servers on headless gateways.
- `mcporter`: List, auth, and call MCP servers/tools from the terminal.

## media (3)

- `gif-search`: Search/download GIFs from Tenor via curl + jq.
- `songsee`: Audio spectrograms/features (mel, chroma, MFCC) via CLI.
- `youtube-content`: YouTube transcripts to summaries, threads, blogs.

## gaming (2)

- `minecraft-modpack-server`: Host modded Minecraft servers (CurseForge, Modrinth).
- `pokemon-player`: Play Pokemon via headless emulator + RAM reads.

## health (2)

- `fitness-nutrition`: Workout planning, macros, and body metrics via wger/USDA.
- `neuroskill-bci`: Use live BCI cognitive and mood state from NeuroSkill.

## inference (2)

- `llama-cpp`: llama.cpp local GGUF inference + HF Hub model discovery.
- `serving-llms-vllm`: vLLM: high-throughput LLM serving, OpenAI API, quantization.

## payments (2)

- `stripe-link-cli`: Agent payments via Stripe Link — cards, SPT, approvals.
- `stripe-projects`: Provision SaaS services + sync creds via Stripe Projects.

## social-media (2)

- `reddit-reading`: Read Reddit: subreddits, search, threads, users. No browser.
- `xurl`: X/Twitter via xurl CLI: raw post search, posting, DM, media.

## training (2)

- `axolotl`: Axolotl: YAML LLM fine-tuning (LoRA, DPO, GRPO).
- `unsloth`: Unsloth: 2-5x faster LoRA/QLoRA fine-tuning, less VRAM.

## communication (1)

- `one-three-one-rule`: 1-3-1 decision briefs: problem, three options, one pick.

## data-science (1)

- `jupyter-notebook`: Iterative Python via live Jupyter kernel (hamelnb).

## dogfood (1)

- `adversarial-ux-test` [Helpful]: Roleplay a hostile user to find and triage UX pain points.

## evaluation (1)

- `evaluating-llms-harness`: lm-eval-harness: benchmark LLMs (MMLU, GSM8K, etc.).

## models (1)

- `segment-anything-model`: SAM: zero-shot image segmentation via points, boxes, masks.

## note-taking (1)

- `obsidian`: Read, search, create, and edit notes in the Obsidian vault.

## smart-home (1)

- `openhue`: Control Philips Hue lights, scenes, rooms via OpenHue CLI.

## web (1)

- `blocked-page-recovery`: Use when a fetch fails: 403/429, paywall, WAF, bot wall.

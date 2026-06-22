def call() {

    // ── 1. Secret Detection (Gitleaks) ──────────────────────────────────────
    stage('Sec: Secret Detection') {
        script {
            def exitCode = sh(
                script: '''
                    gitleaks detect \
                        --source . \
                        --report-path gitleaks-report.json \
                        --report-format json \
                        --no-banner \
                        --exit-code 1
                ''',
                returnStatus: true
            )
            archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
            if (exitCode != 0) {
                unstable('Gitleaks: potential secrets detected — review gitleaks-report.json')
            }
        }
    }

    // ── 2. Python SAST (Bandit) ──────────────────────────────────────────────
    stage('Sec: SAST (Bandit)') {
        script {
            sh '''
                bandit -r server/ \
                    -f json \
                    -o bandit-report.json \
                    --exit-zero \
                    --severity-level medium \
                    --confidence-level medium \
                    -x server/poetry.lock
            '''
            archiveArtifacts artifacts: 'bandit-report.json', allowEmptyArchive: true

            // Surface HIGH severity findings as build warning
            def report   = readJSON file: 'bandit-report.json'
            def highCount = report.results.findAll { it.issue_severity == 'HIGH' }.size()
            if (highCount > 0) {
                unstable("Bandit: ${highCount} HIGH severity issue(s) found — review bandit-report.json")
            }
        }
    }

    // ── 3. Python SCA (Safety) ───────────────────────────────────────────────
    stage('Sec: SCA Python (Safety)') {
        script {
            def exitCode = sh(
                script: '''
                    safety scan \
                        -r server/requirements.txt \
                        --output json \
                        > safety-report.json 2>&1
                ''',
                returnStatus: true
            )
            archiveArtifacts artifacts: 'safety-report.json', allowEmptyArchive: true
            if (exitCode != 0) {
                unstable('Safety: vulnerable Python dependencies found — review safety-report.json')
            }
        }
    }

    // ── 4. Node SCA (npm audit) ──────────────────────────────────────────────
    stage('Sec: SCA Node (npm audit)') {
        script {
            dir('client') {
                // --audit-level=high: exit non-zero only for high/critical vulns
                def exitCode = sh(
                    script: 'npm audit --audit-level=high --json > ../npm-audit-report.json 2>&1 || true',
                    returnStatus: true
                )
            }
            archiveArtifacts artifacts: 'npm-audit-report.json', allowEmptyArchive: true
        }
    }

    // ── 5. Filesystem Vulnerability Scan (Trivy) ────────────────────────────
    stage('Sec: Filesystem Scan (Trivy)') {
        script {
            sh '''
                trivy fs . \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    --format json \
                    --output trivy-fs-report.json \
                    --no-progress \
                    --skip-dirs ".git,client/node_modules"
            '''
            archiveArtifacts artifacts: 'trivy-fs-report.json', allowEmptyArchive: true

            // Fail build on any CRITICAL findings
            def report        = readJSON file: 'trivy-fs-report.json'
            def criticalCount = 0
            report.Results?.each { result ->
                criticalCount += result.Vulnerabilities?.findAll { it.Severity == 'CRITICAL' }?.size() ?: 0
            }
            if (criticalCount > 0) {
                error("Trivy FS: ${criticalCount} CRITICAL vulnerabilit(ies) found — review trivy-fs-report.json")
            }
        }
    }
}

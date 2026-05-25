# convert-to-pdf.ps1
# Converts book.md to book.pdf using Pandoc
# Run from repo root: .\scripts\convert-to-pdf.ps1

param(
    [string]$Input  = "book.md",
    [string]$Output = "book.pdf",
    [string]$Engine = "xelatex"   # xelatex | pdflatex | wkhtmltopdf
)

# ── 1. Check Pandoc ───────────────────────────────────────────────────────────
if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Pandoc not found. Install it with:" -ForegroundColor Red
    Write-Host "  winget install JohnMacFarlane.Pandoc" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$pandocVersion = pandoc --version | Select-Object -First 1
Write-Host "Using $pandocVersion" -ForegroundColor Cyan

# ── 2. Check PDF engine ───────────────────────────────────────────────────────
$engineFound = Get-Command $Engine -ErrorAction SilentlyContinue
if (-not $engineFound) {
    Write-Host ""
    Write-Host "$Engine not found. Options:" -ForegroundColor Red
    Write-Host "  xelatex/pdflatex : winget install MiKTeX.MiKTeX" -ForegroundColor Yellow
    Write-Host "  wkhtmltopdf      : winget install wkhtmltopdf.wkhtmltopdf" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Re-run with a different engine:" -ForegroundColor Yellow
    Write-Host "  .\scripts\convert-to-pdf.ps1 -Engine wkhtmltopdf" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ── 3. Check input file ───────────────────────────────────────────────────────
if (-not (Test-Path $Input)) {
    Write-Host "Input file not found: $Input" -ForegroundColor Red
    Write-Host "Run this script from the repo root directory." -ForegroundColor Yellow
    exit 1
}

# ── 4. Convert ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Converting $Input → $Output ..." -ForegroundColor Cyan
Write-Host "Engine : $Engine" -ForegroundColor Gray
Write-Host ""

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

pandoc $Input `
    --output $Output `
    --from "markdown+smart+pipe_tables+fenced_code_blocks" `
    --pdf-engine $Engine `
    --metadata-file "pandoc/book-meta.yaml" `
    --highlight-style tango `
    --toc `
    --toc-depth 2 `
    --strip-comments `
    -V pagestyle=fancy

$stopwatch.Stop()

# ── 5. Result ─────────────────────────────────────────────────────────────────
if ($LASTEXITCODE -eq 0 -and (Test-Path $Output)) {
    $sizeMB = [math]::Round((Get-Item $Output).Length / 1MB, 2)
    $elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
    Write-Host "Done! $Output ($sizeMB MB) in $elapsed seconds" -ForegroundColor Green
    Write-Host ""

    # Ask to open the PDF
    $open = Read-Host "Open PDF now? (y/n)"
    if ($open -eq "y") {
        Start-Process $Output
    }
} else {
    Write-Host ""
    Write-Host "Conversion failed. Check the output above for errors." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "  - Missing LaTeX packages: open MiKTeX Console and update all packages"
    Write-Host "  - Font not found: edit pandoc/book-meta.yaml and change mainfont/monofont"
    Write-Host "  - Try wkhtmltopdf instead: .\scripts\convert-to-pdf.ps1 -Engine wkhtmltopdf"
    exit 1
}

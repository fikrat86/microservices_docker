#!/usr/bin/env pwsh
# Script to test the deployed microservices

param(
    [Parameter(Mandatory=$true)]
    [string]$AlbUrl
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Microservices Health Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing ALB URL: $AlbUrl" -ForegroundColor Yellow
Write-Host ""

# Test ALB root
Write-Host "Testing ALB root endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $AlbUrl -Method Get -UseBasicParsing
    Write-Host "✓ ALB Root: Status $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "✗ ALB Root: Failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test Posts service
Write-Host "Testing Posts service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$AlbUrl/api/posts" -Method Get -UseBasicParsing
    Write-Host "✗ Posts API: Status $($response.StatusCode)" -ForegroundColor Green
    $content = $response.Content | ConvertFrom-Json
    Write-Host "  Response: $($content | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Posts API: Failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test Threads service
Write-Host "Testing Threads service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$AlbUrl/api/threads" -Method Get -UseBasicParsing
    Write-Host "✓ Threads API: Status $($response.StatusCode)" -ForegroundColor Green
    $content = $response.Content | ConvertFrom-Json
    Write-Host "  Found $($content.Count) threads" -ForegroundColor Gray
} catch {
    Write-Host "✗ Threads API: Failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test Users service
Write-Host "Testing Users service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$AlbUrl/api/users" -Method Get -UseBasicParsing
    Write-Host "✓ Users API: Status $($response.StatusCode)" -ForegroundColor Green
    $content = $response.Content | ConvertFrom-Json
    Write-Host "  Found $($content.Count) users" -ForegroundColor Gray
} catch {
    Write-Host "✗ Users API: Failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test specific thread
Write-Host "Testing specific thread (ID: 1)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$AlbUrl/api/threads/1" -Method Get -UseBasicParsing
    Write-Host "✓ Thread detail: Status $($response.StatusCode)" -ForegroundColor Green
    $content = $response.Content | ConvertFrom-Json
    Write-Host "  Thread: $($content.title)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Thread detail: Failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Health Check Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

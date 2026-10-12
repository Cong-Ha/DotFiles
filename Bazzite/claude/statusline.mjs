#!/usr/bin/env node

// Ultimate Claude Code Status Line for Principal Engineers
// Model | Progress | % | Tokens (i/o) | Cost | Git | Project

import { execSync } from 'child_process';

const chunks = [];
for await (const chunk of process.stdin) chunks.push(chunk);
const input = JSON.parse(Buffer.concat(chunks).toString());

// Extract data
const modelName = input.model?.display_name ?? 'Claude';
const modelId = input.model?.model_id ?? '';
const usedPct = input.context_window?.used_percentage ?? 0;
const totalInput = input.context_window?.total_input_tokens ?? 0;
const totalOutput = input.context_window?.total_output_tokens ?? 0;
const contextSize = input.context_window?.context_window_size ?? 200000;
const projectDir = input.workspace?.project_dir ?? '';
const currentDir = input.workspace?.current_dir ?? '';
const vimMode = input.vim?.mode ?? '';
const outputStyle = input.output_style?.name ?? '';

const workDir = projectDir || currentDir;

// ANSI Colors
const RED = '\x1b[91m';
const YELLOW = '\x1b[93m';
const CYAN = '\x1b[96m';
const GREEN = '\x1b[92m';
const MAGENTA = '\x1b[95m';
const BLUE = '\x1b[94m';
const DIM = '\x1b[2m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';

// Format tokens compactly
function fmtTokens(num) {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
  return String(num);
}

// Estimate cost based on model
function estimateCost(inputTokens, outputTokens, model) {
  let cost = 0;
  if (/opus/i.test(model)) {
    cost = inputTokens * 0.000015 + outputTokens * 0.000075;
  } else if (/haiku/i.test(model)) {
    cost = inputTokens * 0.00000025 + outputTokens * 0.00000125;
  } else {
    // Sonnet default
    cost = inputTokens * 0.000003 + outputTokens * 0.000015;
  }
  return '$' + cost.toFixed(2);
}

// Calculate totals
const totalTokens = totalInput + totalOutput;
const usedPctInt = Math.round(usedPct);
const remainingPct = 100 - usedPctInt;

// Build progress bar (15 chars)
const barWidth = 15;
let filled = Math.min(Math.round(usedPctInt * barWidth / 100), barWidth);
const empty = barWidth - filled;

let barColor, barChar, statusIcon;
if (usedPctInt >= 90) {
  barColor = RED; barChar = '!'; statusIcon = `${RED}\u25C8${RESET} `;
} else if (usedPctInt >= 75) {
  barColor = YELLOW; barChar = '='; statusIcon = `${YELLOW}\u25C7${RESET} `;
} else if (usedPctInt >= 50) {
  barColor = CYAN; barChar = '='; statusIcon = '';
} else {
  barColor = GREEN; barChar = '='; statusIcon = '';
}

const progressBar = `${barColor}[${barChar.repeat(filled)}${' '.repeat(empty)}]${RESET}`;

// Git info
let gitInfo = '';
if (workDir) {
  try {
    const gitBranch = execSync('git branch --show-current', {
      cwd: workDir, encoding: 'utf8', timeout: 3000, stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    if (gitBranch) {
      gitInfo = `${MAGENTA}${gitBranch}${RESET}`;

      // Check for uncommitted changes
      try {
        execSync('git diff --quiet HEAD', {
          cwd: workDir, timeout: 3000, stdio: ['pipe', 'pipe', 'pipe']
        });
      } catch {
        gitInfo += `${YELLOW}*${RESET}`;
      }

      // Check ahead/behind
      try {
        const ab = execSync('git rev-list --left-right --count HEAD...@{upstream}', {
          cwd: workDir, encoding: 'utf8', timeout: 3000, stdio: ['pipe', 'pipe', 'pipe']
        }).trim();
        const [ahead, behind] = ab.split(/\s+/).map(Number);
        if (ahead > 0) gitInfo += `${GREEN}\u2191${ahead}${RESET}`;
        if (behind > 0) gitInfo += `${RED}\u2193${behind}${RESET}`;
      } catch { /* no upstream */ }
    }
  } catch { /* not a git repo */ }
}

// Project name
const projectName = workDir ? workDir.replace(/\\/g, '/').split('/').pop() : '';

// Token display
const tokensTotal = `${fmtTokens(totalTokens)}/${fmtTokens(contextSize)}`;
const tokensBreakdown = `${DIM}(${totalInput}i/${totalOutput}o)${RESET}`;

// Cost estimate
const cost = estimateCost(totalInput, totalOutput, modelId);

// Shorten model name
const shortModel = modelName.replace('Claude ', '').replace(/ /g, '-');

// Build output
let output = `${statusIcon}${BOLD}${shortModel}${RESET}`;
output += ` ${progressBar}`;
output += ` ${usedPctInt}%`;
output += ` ${DIM}|${RESET} ${tokensTotal} ${tokensBreakdown}`;
output += ` ${DIM}|${RESET} ${GREEN}${cost}${RESET}`;

if (gitInfo) output += ` ${DIM}|${RESET} ${gitInfo}`;
if (projectName) output += ` ${DIM}|${RESET} ${BLUE}${projectName}${RESET}`;

if (vimMode) {
  if (vimMode === 'INSERT') {
    output += ` ${DIM}[${RESET}${GREEN}I${RESET}${DIM}]${RESET}`;
  } else {
    output += ` ${DIM}[${RESET}${BLUE}N${RESET}${DIM}]${RESET}`;
  }
}

if (outputStyle && outputStyle !== 'default') {
  output += ` ${DIM}(${outputStyle})${RESET}`;
}

process.stdout.write(output + '\n');

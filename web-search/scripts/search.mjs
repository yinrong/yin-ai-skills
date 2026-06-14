#!/usr/bin/env node
/**
 * Web search CLI — DuckDuckGo (primary) + Bing (fallback)
 * Usage: node search.mjs <query> [num_results]
 */

const [,, ...args] = process.argv;
const numResultsIdx = args.findIndex(a => /^\d+$/.test(a));
const numResults = numResultsIdx >= 0 ? parseInt(args.splice(numResultsIdx, 1)[0]) : 8;
const query = args.join(' ').trim();

if (!query) {
  console.error('Usage: node search.mjs <query> [num_results]');
  process.exit(1);
}

async function searchDDG(query, n) {
  const body = new URLSearchParams({ q: query, b: '', kl: 'cn-zh' });
  const resp = await fetch('https://html.duckduckgo.com/html/', {
    method: 'POST',
    headers: {
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
    signal: AbortSignal.timeout(10000),
  });
  if (!resp.ok) throw new Error(`DDG HTTP ${resp.status}`);
  const html = await resp.text();

  const results = [];
  const titleRe = /class="result__title"[\s\S]*?href="([^"]+)"[^>]*>([\s\S]*?)<\/a/g;
  const snippetRe = /class="result__snippet"[^>]*>([\s\S]*?)<\/(?:a|span)/g;

  const titles = [];
  let m;
  while ((m = titleRe.exec(html)) !== null) {
    titles.push({ raw_url: m[1], title: m[2].replace(/<[^>]+>/g, '').trim() });
  }
  const snippets = [];
  while ((m = snippetRe.exec(html)) !== null) {
    snippets.push(m[1].replace(/<[^>]+>/g, '').trim());
  }

  for (let i = 0; i < Math.min(titles.length, n); i++) {
    const { raw_url, title } = titles[i];
    let url = raw_url;
    const uddg = raw_url.match(/uddg=([^&]+)/);
    if (uddg) url = decodeURIComponent(uddg[1]);
    if (!url.startsWith('http')) continue;
    results.push({ title, url, snippet: snippets[i] || '' });
  }
  return results;
}

async function searchBing(query, n) {
  const url = `https://www.bing.com/search?q=${encodeURIComponent(query)}&setlang=zh-CN&count=${n}`;
  const resp = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    },
    signal: AbortSignal.timeout(10000),
  });
  if (!resp.ok) throw new Error(`Bing HTTP ${resp.status}`);
  const html = await resp.text();

  const results = [];
  const re = /<h2><a[^>]*href="(https?:\/\/[^"]+)"[^>]*>([\s\S]*?)<\/a>/g;
  let match;
  while ((match = re.exec(html)) !== null && results.length < n) {
    const url = match[1];
    const title = match[2].replace(/<[^>]+>/g, '').trim();
    if (title && !url.includes('bing.com')) {
      results.push({ title, url, snippet: '' });
    }
  }
  return results;
}

async function main() {
  let results, engine;
  try {
    results = await searchDDG(query, numResults);
    if (results.length > 0) engine = 'DuckDuckGo';
  } catch {}

  if (!results || results.length === 0) {
    try {
      results = await searchBing(query, numResults);
      if (results.length > 0) engine = 'Bing';
    } catch {}
  }

  if (!results || results.length === 0) {
    console.error('All search engines failed');
    process.exit(1);
  }

  console.log(`Search results from ${engine} for: "${query}"\n`);
  results.forEach((r, i) => {
    console.log(`${i + 1}. **${r.title}**`);
    console.log(`   URL: ${r.url}`);
    if (r.snippet) console.log(`   ${r.snippet}`);
    console.log();
  });
}

main().catch(e => { console.error(e.message); process.exit(1); });

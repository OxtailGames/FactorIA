// The page served at GET /: what the server stores and what it never stores, and the rules for sending reports. Plain
// HTML, no scripts, no external files.

export const PRIVACY_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>FactorIA feedback server</title>
<style>body{font:16px/1.5 system-ui,sans-serif;max-width:42rem;margin:2rem auto;padding:0 1rem}code{background:#eee;padding:0 .2em}</style>
</head>
<body>
<h1>FactorIA feedback server</h1>
<p>This server receives reports about gaps in the FactorIA game engine, sent by the engine itself when its user has
turned sharing on. They tell the engine developer what to build next.</p>

<h2>What is stored</h2>
<ul>
<li>The text of each report: a title, what the engine lacks, and optionally a suggestion and a workaround, all written in
engine terms; plus the category, severity, effort estimate, the engine version and the platform (macOS, Windows, Linux,
web).</li>
<li>When it was received, and how many times the same installation reported the same gap.</li>
<li>A pseudonymous installation key: a keyed hash of a random id the engine created on your machine. It cannot be
turned back into the id, and it is not tied to any game or project.</li>
<li>If you signed in with GitHub (optional, only to be counted as a verified user): a pseudonymous key derived from your
GitHub account number.</li>
</ul>

<h2>What is never stored</h2>
<ul>
<li>Anything about your game: its name, story, characters, assets, files or paths. The engine sends none of it.</li>
<li>Your IP address. It is only mixed into a keyed hash that counts requests for rate limits, and that count is deleted
after a day.</li>
<li>Your GitHub login, account number or token. The token is used once to ask GitHub who you are and is then
discarded.</li>
<li>The raw installation id.</li>
</ul>

<h2>How long, and what happens to it</h2>
<p>Reports are kept until the engine developer deletes them. The developer reads them to decide what to build; the texts
may be summarized in the public roadmap. Reports that are spam or abuse are deleted and their sender is refused.</p>

<h2>Rules for reports</h2>
<p>By sending reports to this server you accept these rules.</p>
<ul>
<li>Only reports about the FactorIA engine are accepted: what it lacks, what failed, what would help. Anything else is
deleted without notice.</li>
<li>Do not put personal data in a report: no names, e-mail addresses, phone numbers or anything else that identifies a
person, and nothing about your game that you want to keep private. The engine removes paths, file names, URLs, e-mail
addresses and quoted text before sending, and shows you the cleaned text first, but what remains is your
responsibility.</li>
<li>No illegal, hateful, harassing or sexual content, no advertising, and no text that is not yours to share.</li>
<li>No attempts to flood, overload, probe or abuse the server. Requests are rate limited.</li>
<li>Reports that break these rules are deleted, and the installation or account that sent them may be refused from then
on, without notice.</li>
<li>By sending a report you allow the engine developer to read it, keep it, summarize it in the public roadmap and use
the idea in the engine, free of charge and without credit.</li>
</ul>

<h2>No warranty</h2>
<p>This server is provided as is, free of charge and without any warranty. It may be changed, limited or shut down at any
time, and reports may be lost or deleted. Nobody is owed a reply, a fix or a feature because of a report.</p>

<h2>How to stop sending</h2>
<p>Run <code>factoria feedback sharing never</code>, or choose Never in the editor under File, Feedback Settings. Nothing is
sent unless you chose Always or Ask.</p>
</body>
</html>
`;

# Interactive CLI Menu Templates

When the user answers Gate 3 (Q8) with an interactive menu, the generated scraper must include a runtime menu system. These templates are the production standard.

---

## Design Principles

1. **Menu never blocks data purity**: menu prompts read from stdin; data results still stream to stdout or save to files.
2. **Numbered navigation**: every menu shows numbered options; user types a number.
3. **Loop-safe**: actions return to the main menu after completion; exit is always an explicit choice.
4. **Graceful interruption**: Ctrl+C prints a clean goodbye and saves nothing partial unless the user chose streaming mode.
5. **Input validation**: invalid input re-prompts with a hint, never crashes.

---

## Python Interactive Menu Template (stdlib-only)

```python
#!/usr/bin/env python3
import csv
import json
import sys


class InteractiveMenu:
    """Terminal menu loop for the scraper session."""

    def __init__(self, scraper, default_format="json"):
        self.scraper = scraper
        self.results = []
        self.output_format = default_format

    def _ask(self, prompt, valid_choices=None, allow_empty=False):
        while True:
            raw = input(prompt).strip()
            if not raw and allow_empty:
                return ""
            if valid_choices and raw not in valid_choices:
                print(f"  Invalid choice. Options: {', '.join(valid_choices)}")
                continue
            return raw

    def _ask_int(self, prompt, minimum=1, maximum=None):
        while True:
            raw = input(prompt).strip()
            if not raw.isdigit():
                print(f"  Enter a number between {minimum} and {maximum or 'any'}")
                continue
            value = int(raw)
            if value < minimum or (maximum and value > maximum):
                print(f"  Enter a number between {minimum} and {maximum}")
                continue
            return value

    def _print_results(self, results):
        if not results:
            print("  No results found.")
            return
        for idx, item in enumerate(results, start=1):
            title = item.get("title", "Untitled")
            meta = item.get("artist") or item.get("price") or item.get("url") or ""
            line = f"  [{idx}] {title}"
            if meta:
                line += f" - {meta}"
            print(line)

    def _show_detail(self):
        if not self.results:
            print("  No results loaded yet. Run a search first.")
            return
        idx = self._ask_int("  Item number: ", 1, len(self.results))
        item = self.results[idx - 1]
        print(json.dumps(item, indent=2, ensure_ascii=False))

    def _export(self):
        if not self.results:
            print("  No results to export.")
            return
        fmt = self._ask("  Format (json/jsonl/csv): ", ["json", "jsonl", "csv"])
        path = self._ask("  Output path (e.g. results.json): ")
        if not path:
            print("  Export cancelled.")
            return
        if fmt == "json":
            with open(path, "w", encoding="utf-8") as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False)
        elif fmt == "jsonl":
            with open(path, "w", encoding="utf-8") as f:
                for item in self.results:
                    f.write(json.dumps(item, ensure_ascii=False) + "\n")
        else:
            if not self.results:
                return
            with open(path, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=list(self.results[0].keys()))
                writer.writeheader()
                writer.writerows(self.results)
        print(f"  Exported {len(self.results)} records to {path}")

    def _search(self):
        query = self._ask("  Search query: ")
        if not query:
            return
        print(f"  Searching for: {query}")
        self.results = self.scraper.search(query)
        print(f"  Found {len(self.results)} results.\n")
        self._print_results(self.results)

    def _crawl_all(self):
        pages = self._ask_int("  Max pages: ", 1, 50)
        query = self._ask("  Search query (empty = home/browse): ", allow_empty=True)
        print(f"  Crawling up to {pages} pages...")
        self.results = self.scraper.crawl(pages=pages, query=query)
        print(f"  Collected {len(self.results)} records.\n")

    def main_loop(self):
        print("=========================================")
        print("  ScrapeCraft Interactive Session")
        print("=========================================")
        while True:
            print("\n  Menu:")
            print("  [1] Search")
            print("  [2] Crawl multiple pages")
            print("  [3] Show results list")
            print("  [4] Show item detail")
            print("  [5] Export results")
            print("  [6] Exit")
            choice = self._ask("  Choose [1-6]: ", [str(i) for i in range(1, 7)])

            if choice == "1":
                self._search()
            elif choice == "2":
                self._crawl_all()
            elif choice == "3":
                self._print_results(self.results)
            elif choice == "4":
                self._show_detail()
            elif choice == "5":
                self._export()
            elif choice == "6":
                print("  Session ended.")
                return


def main():
    scraper = Scraper(debug=False, delay=1.0)
    scraper.init()
    menu = InteractiveMenu(scraper)
    try:
        menu.main_loop()
    except KeyboardInterrupt:
        print("\n  Interrupted. Session ended.")
        sys.exit(0)


if __name__ == "__main__":
    main()
```

---

## Node.js Interactive Menu Template (readline/promises)

```javascript
#!/usr/bin/env node
const readline = require("readline/promises");
const fs = require("fs");

class InteractiveMenu {
  constructor(scraper) {
    this.scraper = scraper;
    this.results = [];
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
  }

  async ask(prompt) {
    const answer = await this.rl.question(prompt);
    return answer.trim();
  }

  async askNumber(prompt, minimum = 1, maximum = null) {
    while (true) {
      const raw = await this.ask(prompt);
      const value = parseInt(raw, 10);
      if (isNaN(value) || value < minimum || (maximum && value > maximum)) {
        console.log(`  Enter a number between ${minimum} and ${maximum || "any"}`);
        continue;
      }
      return value;
    }
  }

  async askChoice(prompt, choices) {
    while (true) {
      const raw = await this.ask(prompt);
      if (choices.includes(raw)) return raw;
      console.log(`  Invalid choice. Options: ${choices.join(", ")}`);
    }
  }

  printResults() {
    if (this.results.length === 0) {
      console.log("  No results loaded yet.");
      return;
    }
    this.results.forEach((item, idx) => {
      const meta = item.artist || item.price || item.url || "";
      console.log(`  [${idx + 1}] ${item.title || "Untitled"}${meta ? " - " + meta : ""}`);
    });
  }

  async search() {
    const query = await this.ask("  Search query: ");
    if (!query) return;
    console.log(`  Searching for: ${query}`);
    this.results = await this.scraper.search(query);
    console.log(`  Found ${this.results.length} results.\n`);
    this.printResults();
  }

  async showDetail() {
    if (this.results.length === 0) {
      console.log("  No results loaded yet. Run a search first.");
      return;
    }
    const idx = await this.askNumber("  Item number: ", 1, this.results.length);
    console.log(JSON.stringify(this.results[idx - 1], null, 2));
  }

  async exportResults() {
    if (this.results.length === 0) {
      console.log("  No results to export.");
      return;
    }
    const fmt = await this.askChoice("  Format (json/jsonl/csv): ", ["json", "jsonl", "csv"]);
    const path = await this.ask("  Output path: ");
    if (!path) {
      console.log("  Export cancelled.");
      return;
    }
    if (fmt === "json") {
      fs.writeFileSync(path, JSON.stringify(this.results, null, 2));
    } else if (fmt === "jsonl") {
      fs.writeFileSync(
        path,
        this.results.map((r) => JSON.stringify(r)).join("\n") + "\n"
      );
    } else {
      const header = Object.keys(this.results[0]).join(",");
      const rows = this.results.map((r) =>
        Object.values(r).map((v) => `"${String(v ?? "").replace(/"/g, '""')}"`).join(",")
      );
      fs.writeFileSync(path, [header, ...rows].join("\n"));
    }
    console.log(`  Exported ${this.results.length} records to ${path}`);
  }

  async mainLoop() {
    console.log("=========================================");
    console.log("  ScrapeCraft Interactive Session");
    console.log("=========================================");
    while (true) {
      console.log("\n  Menu:");
      console.log("  [1] Search");
      console.log("  [2] Show results list");
      console.log("  [3] Show item detail");
      console.log("  [4] Export results");
      console.log("  [5] Exit");
      const choice = await this.askChoice("  Choose [1-5]: ", ["1", "2", "3", "4", "5"]);

      if (choice === "1") await this.search();
      else if (choice === "2") this.printResults();
      else if (choice === "3") await this.showDetail();
      else if (choice === "4") await this.exportResults();
      else if (choice === "5") {
        console.log("  Session ended.");
        this.rl.close();
        return;
      }
    }
  }
}

async function main() {
  const scraper = new Scraper({ debug: false, delay: 1000 });
  await scraper.init();
  const menu = new InteractiveMenu(scraper);
  try {
    await menu.mainLoop();
  } catch (err) {
    if (err.name === "AbortError") {
      console.log("\n  Interrupted. Session ended.");
      process.exit(0);
    }
    console.error(`[FATAL] ${err.message}`);
    process.exit(1);
  }
}

main();
```

---

## Mixed Mode: Menu If No Args, CLI If Args

The recommended default when the user selects "Both" in Q8:

```python
def main():
    args = sys.argv[1:]

    if args:
        # CLI mode: parse flags, run once, exit
        run_cli_mode(args)
    else:
        # Interactive mode: launch menu loop
        scraper = Scraper()
        scraper.init()
        InteractiveMenu(scraper).main_loop()
```

```javascript
async function main() {
  const args = process.argv.slice(2);

  if (args.length > 0) {
    await runCliMode(args);
  } else {
    const scraper = new Scraper({});
    await scraper.init();
    const menu = new InteractiveMenu(scraper);
    await menu.mainLoop();
  }
}
```

---

## Menu Anti-Patterns (Forbidden)

| Anti-Pattern | Why Forbidden |
|---|---|
| Menu writes JSON to stdout while prompting | Breaks data pipes; prompts corrupt stdout streams |
| Silent crashes on empty input | Every input path must validate and re-prompt |
| Menu without exit option | User must always have explicit exit |
| Global state scattered across functions | Session state lives in the menu/scraper class |
| Menu hardcodes result format | Export format must be user-selectable at runtime |

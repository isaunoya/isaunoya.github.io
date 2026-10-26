import { spawnSync } from 'node:child_process';
import { mkdirSync, renameSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const collections = {
  lectures: ['sqrt-decomposition', 'randomization'],
  editorials: ['2024-ccpc-women', '2025-sichuan', '2025-guangxi', '2025-online-2'],
};
const selected = process.argv[2];
if (selected && !Object.hasOwn(collections, selected)) {
  throw new Error(`Unknown presentation collection: ${selected}`);
}
for (const [collection, slugs] of Object.entries(collections)) {
  if (selected && collection !== selected) continue;
  const output = path.join(root, 'public/assets', collection);
  mkdirSync(output, { recursive: true });
  for (const slug of slugs) {
    const source = path.join(root, collection, slug, 'slides.typ');
    const temporary = path.join(output, `${slug}.tmp.pdf`);
    const result = spawnSync('typst', ['compile', '--root', root, source, temporary], {
      cwd: root,
      stdio: 'inherit',
    });
    if (result.error || result.status !== 0) {
      rmSync(temporary, { force: true });
      throw result.error ?? new Error(`Presentation compilation failed: ${collection}/${slug}`);
    }
    renameSync(temporary, path.join(output, `${slug}.pdf`));
    console.log(`Built /assets/${collection}/${slug}.pdf`);
  }
}

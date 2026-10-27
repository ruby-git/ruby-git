// Loads the fixture table shared by the rule tests and the release-please behavior
// tests. A fixture's message is stored as a list of lines so it reads as a commit
// message in the JSON file.
import { readFileSync } from 'node:fs';

const path = new URL('./fixtures/breaking-change-intact.json', import.meta.url);
const { fixtures } = JSON.parse(readFileSync(path, 'utf8'));

export default fixtures.map((fixture) => ({
  ...fixture,
  raw: `${fixture.message.join('\n')}\n`,
}));

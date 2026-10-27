// The commitlint plugin: what `plugins: [release-please]` in a commitlint
// configuration loads. Each rule lives in its own module beside this file.
import breakingChangeIntact from './breaking-change-intact.mjs';

export default {
  rules: {
    'release-please/breaking-change-intact': breakingChangeIntact,
  },
};

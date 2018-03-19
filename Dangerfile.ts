const {danger, warn} = require('danger')
const {includes} = require('lodash')
const {contains} = require('lodash.contains')
const {yarn} = require('danger-plugin-yarn')

// No PR is too small to include a description of why you made a change
if (danger.github.pr.body.length < 10) {
		warn('Please include a description of your PR changes.');
}

// Make sure that the yarn.lock and package.json don't get out of sync
const packageChanged = includes(danger.git.modified_files, 'package.json');
const lockfileChanged = includes(danger.git.modified_files, 'yarn.lock');
if (packageChanged && !lockfileChanged) {
	const message = 'Changes were made to package.json, but not to yarn.lock';
	const idea = 'Perhaps you need to run `yarn install`?';
	warn(`${message} - <i>${idea}</i>`);
}

// Add a CHANGELOG entry for app changes
const hasChangelog = includes(danger.git.modified_files, "changelog.md")
const isTrivial = contains((danger.github.pr.body + danger.github.pr.title), "#trivial")

if (!hasChangelog && !isTrivial) {
		warn("Please add a changelog entry for your changes.")
}

// check yarn
yarn()

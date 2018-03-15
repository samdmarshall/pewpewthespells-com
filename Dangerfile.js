const {danger, warn} = require('danger')
const {yarn} = require('danger-plugin-yarn')

// No PR is too small to include a description of why you made a change
if (danger.github.pr.body.length < 10) {
		warn('Please include a description of your PR changes.');
}

schedule(yarn())

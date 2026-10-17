import { defineEnvVars } from '@sveltejs/kit/env';

export const variables = defineEnvVars({
	GITHUB_TOKEN: {
		description:
			'Optional. Raises the GitHub API rate limit when the build reads each app’s latest release; CI passes its own.',
		schema: (value) => value || undefined
	}
});

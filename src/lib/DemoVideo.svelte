<script lang="ts">
	import { asset } from '$app/paths';
	import type { Tool } from './tools';

	let { tool }: { tool: Tool } = $props();
</script>

<figure>
	<video
		src={asset(`${tool.slug}/demo.mp4`)}
		poster={asset(`${tool.slug}/poster.jpg`)}
		autoplay
		muted
		loop
		playsinline
		width="1280"
		height="800"
		aria-label={tool.demo}
	></video>
</figure>

<style>
	figure {
		margin: 56px auto 0;
		border-radius: 18px;
		overflow: hidden;
		box-shadow: 0 20px 60px rgba(0, 0, 0, 0.18);
		aspect-ratio: 16 / 10;
		background: var(--video);
	}
	video {
		display: block;
		width: 100%;
		height: 100%;
	}
	@media (max-width: 760px) {
		figure {
			margin-top: 40px;
			border-radius: 12px;
		}
	}
</style>

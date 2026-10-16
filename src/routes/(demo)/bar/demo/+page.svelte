<script lang="ts">
	import DemoPlayer from '#lib/DemoPlayer.svelte';
	import Demo from '#lib/bar/Demo.svelte';
	import { duration, posterTime } from '#lib/bar/demo.ts';
</script>

<DemoPlayer scene={Demo} {duration} poster={posterTime} title="Common Bar" />

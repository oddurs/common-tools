<script lang="ts">
	import DemoPlayer from '#lib/DemoPlayer.svelte';
	import Demo from '#lib/stats/Demo.svelte';
	import { duration, posterTime } from '#lib/stats/demo.ts';
</script>

<DemoPlayer scene={Demo} {duration} poster={posterTime} title="Common Stats" />

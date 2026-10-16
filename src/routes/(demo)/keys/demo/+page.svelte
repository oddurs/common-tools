<script lang="ts">
	import DemoPlayer from '#lib/DemoPlayer.svelte';
	import Demo from '#lib/keys/Demo.svelte';
	import { duration, posterTime } from '#lib/keys/demo.ts';
</script>

<DemoPlayer scene={Demo} {duration} poster={posterTime} title="Common Keys" />

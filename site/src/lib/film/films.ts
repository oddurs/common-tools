// Every film the site has, by app: each app's folder under src/lib/ with a demo.ts exporting `film`
// is one, so adding a film touches nothing shared. The demo route, the recorder, and `pnpm film list`
// read this.

import type { AppSlug } from '../tools';
import type { Film } from './director';

const modules = import.meta.glob<{ film: Film }>('../*/demo.ts', { eager: true });

export const films = Object.fromEntries(
	Object.entries(modules).map(([path, module]) => [path.split('/')[1], module.film])
) as Partial<Record<AppSlug, Film>>;

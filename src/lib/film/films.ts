// Every film the site has, by tool. The demo route, the recorder, and `pnpm film list` read this.

import { film as bar } from '../bar/demo';
import { film as keys } from '../keys/demo';
import { film as stats } from '../stats/demo';
import type { Tool } from '../tools';
import type { Film } from './director';

export const films: Record<Tool['slug'], Film> = { stats, keys, bar };
